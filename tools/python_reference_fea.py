# Python mirror of fea/F1_Sled_Plate_FEA.m, used to cross-check the MATLAB results.
import numpy as np, scipy.sparse as sp, scipy.sparse.linalg as spl
E=210e9; nu=0.3; fy=355e6
def solve(nx,ny,t,F,patch,Lx=2.0,Ly=1.0,mounts=(0.3,1.0,1.7),mw=0.2):
    xs=np.linspace(0,Lx,nx+1); ys=np.linspace(0,Ly,ny+1)
    nid=lambda i,j: j*(nx+1)+i
    N=(nx+1)*(ny+1); C=E/(1-nu**2)*np.array([[1,nu,0],[nu,1,0],[0,0,(1-nu)/2]])
    dx=Lx/nx; dy=Ly/ny
    gp=[-1/np.sqrt(3),1/np.sqrt(3)]
    def B(xi,eta):
        dNx=0.25*np.array([-(1-eta),(1-eta),(1+eta),-(1+eta)])*2/dx
        dNy=0.25*np.array([-(1-xi),-(1+xi),(1+xi),(1-xi)])*2/dy
        b=np.zeros((3,8)); b[0,0::2]=dNx; b[1,1::2]=dNy; b[2,0::2]=dNy; b[2,1::2]=dNx; return b
    Ke=sum(B(a,b).T@C@B(a,b)*(dx*dy/4)*t for a in gp for b in gp)
    I=[];J=[];V=[]
    conn=[]
    for j in range(ny):
        for i in range(nx):
            n=[nid(i,j),nid(i+1,j),nid(i+1,j+1),nid(i,j+1)]; conn.append(n)
            dof=np.ravel([[2*k,2*k+1] for k in n])
            I+=list(np.repeat(dof,8)); J+=list(np.tile(dof,8)); V+=list(Ke.ravel())
    K=sp.csr_matrix((V,(I,J)),shape=(2*N,2*N))
    f=np.zeros(2*N)
    # load: traction on front edge y=Ly over patch, consistent nodal loads
    q=F/(patch[1]-patch[0])
    for i in range(nx):
        x0,x1=xs[i],xs[i+1]; a,b=max(x0,patch[0]),min(x1,patch[1])
        if b>a:
            L=b-a; # linear shape fn split
            xm=(a+b)/2; w1=(x1-xm)/dx; f[2*nid(i,ny)+1]-=q*L*w1; f[2*nid(i+1,ny)+1]-=q*L*(1-w1)
    fixed=set()
    for i,x in enumerate(xs):
        for m in mounts:
            if abs(x-m)<=mw/2+1e-9: fixed.add(2*nid(i,0)+1)
    ic=int(np.argmin(abs(xs-1.0))); fixed.add(2*nid(ic,0))
    free=np.array(sorted(set(range(2*N))-fixed))
    u=np.zeros(2*N); u[free]=spl.spsolve(K[free][:,free].tocsc(),f[free])
    vm=[]; 
    for n in conn:
        dof=np.ravel([[2*k,2*k+1] for k in n]); s=C@B(0,0)@u[dof]
        vm.append(np.sqrt(s[0]**2-s[0]*s[1]+s[1]**2+3*s[2]**2))
    vm=np.array(vm).reshape(ny,nx)
    # stress in the interior, excluding one 0.1 m band at the supported edge
    band=int(np.ceil(0.1/dy)); interior=vm[band:,:].max()
    disp=np.sqrt(u[0::2]**2+u[1::2]**2).max()
    return vm.max()/1e6, interior/1e6, disp*1e3
for name,patch in [('centred',(0.7,1.3)),('offset end',(0.0,0.6))]:
    for t in [0.020,0.030]:
        for nx,ny in [(20,10),(40,20),(80,40)]:
            mx,inn,d=solve(nx,ny,t,600e3,patch)
            print('%-10s t=%2.0fmm mesh %2dx%2d  maxVM %6.1f MPa  VM>0.1m from supports %6.1f MPa  SF %.2f  max disp %.3f mm'%(name,t*1e3,nx,ny,mx,inn,355/inn,d))
