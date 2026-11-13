-- Ejecutar desde la raíz: luajit addons/KnuUI/tools/render/tests.lua <SavedVariables>
local dir='addons/KnuUI/tools/render/'
local loader=dofile(dir..'loader.lua')
local geometry=dofile(dir..'geometry.lua')
local models=dofile(dir..'models.lua')
local output=dofile(dir..'output.lua')
local checks=0
local function eq(a,b)
 checks=checks+1
 assert(a==b,tostring(a)..' ~= '..tostring(b))
end
local function near(a,b) checks=checks+1; assert(math.abs(a-b)<1e-8,tostring(a)..' ~= '..tostring(b)) end
local dst=loader.merge({nested={a=1,b=2},flag=true},{nested={a=9},flag=false})
eq(dst.nested.a,9); eq(dst.nested.b,2); eq(dst.flag,false)
local nodes={
 a={width=100,height=40,position='TOPRIGHT,UIParent,TOPRIGHT,-8,-8'},
 b={width=20,height=10,position='BOTTOMLEFT,frameA,TOPRIGHT,2,3'},
 cycle1={width=1,height=1,position='CENTER,cycle2,CENTER,0,0'},
 cycle2={width=1,height=1,position='CENTER,cycle1,CENTER,0,0'},
 missing={width=1,height=1,position='TOP,absent,TOP,0,0'},
}
local get=geometry.resolve(nodes,{frameA='a'})
eq(get('a').left,1812); eq(get('a').bottom,1032)
eq(get('b').left,1914); eq(get('b').bottom,1075)
local r,err=get('cycle1'); eq(r,nil); assert(err:find('ciclo'))
r,err=get('missing'); eq(r,nil); assert(err:find('absent'))
for name,p in pairs(geometry.points) do
 local resolve=geometry.resolve({test={width=100,height=50,position=name..',UIParent,'..name..',3,-7'}},{})
 near(resolve('test').left,(1920-100)*p[1]+3)
 near(resolve('test').bottom,(1080-50)*p[2]-7)
end
eq(geometry.parse('TOP\031UIParent\031TOP\0311\0312')[4],1)
eq(geometry.parse('mal'),nil)
local function rect(x,y,w,h) return {name=tostring(x),left=x,bottom=y,width=w,height=h} end
eq(#geometry.intersections({rect(0,0,10,10),rect(10,0,10,10)}),0)
eq(#geometry.intersections({rect(0,0,10,10),rect(8,8,10,10)}),0)
local overlap=geometry.intersections({rect(0,0,10,10),rect(7,8,10,10)})
eq(#overlap,1); eq(overlap[1].area,6)
eq(output.json({s='"\\\n\0',b=false}),'{"b":false,"s":"\\"\\\\\\n\\u0000"}')

-- Conversión compartida: capacidad de auras, deshabilitados y anclas inválidas.
local rects, skipped = geometry.rectangles({
 aura={enabled=true,width=10,height=5,position='TOPRIGHT,UIParent,TOPRIGHT,0,0',
  drawWidth=30,drawHeight=20,drawAnchor='TOPRIGHT',approximate=true},
 hidden={enabled=false,width=1,height=1},
 missing={enabled=true,width=1,height=1,position='CENTER,absent,CENTER,0,0'},
 marker={enabled=true,width=20,height=20,position='TOPRIGHT,UIParent,TOPRIGHT,0,0',unknown=true},
}, {})
eq(#rects,2); eq(#skipped,1); assert(skipped[1]:find('absent'))
eq(rects[1].name,'aura'); eq(rects[1].left,1890); eq(rects[1].bottom,1060)
eq(rects[1].width,30); eq(rects[1].height,20); eq(rects[1].moverWidth,10)
eq(rects[1].approximate,true); eq(rects[2].unknown,true)
eq(#geometry.intersections(rects),0)

local path=assert(arg[1],'Indicá el archivo SavedVariables de prueba')
local before=loader.read(path)
-- Personaje opcional como segundo argumento (sin él, sólo si hay uno solo en el archivo).
local c=loader.load('.',path,arg[2])
assert(type(c.profile)=='string' and c.profile~='','sin perfil')
eq(rawget(_G,'ElvDB'),nil); eq(rawget(_G,'ElvUI'),nil)
local byProfile=loader.load('.',path,nil,c.profile)
eq(byProfile.db.chat.panelWidth,c.db.chat.panelWidth)
local ok=pcall(loader.load,'.',path,'personaje inexistente')
eq(ok,false)
-- Casos independientes del perfil: filas parciales, altura libre y fondo multiplicado.
local b=c.db.actionbar.bar1
b.enabled=true; b.buttons=7; b.buttonsPerRow=3; b.buttonSize=20
b.keepSizeRatio=false; b.buttonHeight=12; b.buttonSpacing=2
b.backdrop=false; b.backdropSpacing=4; b.widthMult=2; b.heightMult=3
c.db.KnuUITanks=false
local n,aliases=models.build(c,'.',loader)
eq(n.ElvAB_1.width,64); eq(n.ElvAB_1.height,40)
eq(n.KnuUI_ManaTankMover.enabled,false)
eq(aliases.ElvUI_MinimapHolder,'MinimapMover')
b.backdrop=true
n,aliases=models.build(c,'.',loader)
eq(n.ElvAB_1.width,138); eq(n.ElvAB_1.height,132)
local resolve=geometry.resolve(n,aliases)
local bar, mover=resolve('ElvUI_Bar1'),resolve('ElvAB_1')
local left=b.point=='BOTTOMRIGHT' or b.point=='TOPRIGHT'
local up=b.point=='BOTTOMLEFT' or b.point=='BOTTOMRIGHT'
eq(bar.left-mover.left,left and 1 or -1)
eq(bar.bottom-mover.bottom,up and -1 or 1)
b.keepSizeRatio=true; b.widthMult=1; b.heightMult=1
n=models.build(c,'.',loader)
eq(n.ElvAB_1.height,72)
-- El grupo completo conserva los espacios entre grupos y descuenta el borde final.
local party=c.db.unitframe.units.party
party.width=80; party.height=30; party.infoPanel.enable=false
party.horizontalSpacing=3; party.verticalSpacing=2; party.groupSpacing=7
party.growthDirection='DOWN_RIGHT'
local raid=c.db.unitframe.units.raid1
raid.width=80; raid.height=30; raid.infoPanel.enable=false
raid.horizontalSpacing=3; raid.verticalSpacing=2; raid.groupSpacing=7
raid.growthDirection='DOWN_RIGHT'; raid.groupsPerRowCol=2; raid.numGroups=4
local a=c.db.auras.buffs
a.size=20; a.height=12; a.keepSizeRatio=false; a.wrapAfter=3; a.maxWraps=2
a.horizontalSpacing=2; a.verticalSpacing=5; a.growthDirection='DOWN_RIGHT'
n=models.build(c,'.',loader)
eq(n.ElvUF_PartyMover.width,80); eq(n.ElvUF_PartyMover.height,158)
eq(n.ElvUF_Raid1Mover.width,170); eq(n.ElvUF_Raid1Mover.height,325)
eq(n.BuffsMover.width,20); eq(n.BuffsMover.height,42)
eq(n.BuffsMover.drawWidth,45); eq(n.BuffsMover.drawHeight,40)
eq(n.BuffsMover.drawAnchor,'TOPLEFT')
eq(loader.read(path),before)
print('Pruebas: '..checks..' verificaciones correctas; SavedVariables intactas.')
