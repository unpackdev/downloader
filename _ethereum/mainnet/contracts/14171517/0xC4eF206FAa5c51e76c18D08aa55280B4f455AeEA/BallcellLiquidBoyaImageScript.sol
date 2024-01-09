// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ----------------------------------------------------------------
// ----------------------------------------------------------------
// ----------------------------------------------------------------

library BallcellLiquidBoyaImageScript {
	string constant code = '"use strict";window.startPuppet=(()=>{let t=(t,e)=>e.forEach(((e,l)=>t[l]=e)),e=(t,e,l,r)=>Array(4).fill(0).map(((o,h)=>t[12+h]=t[0+h]*e+t[4+h]*l+t[8+h]*r+t[12+h])),l=(t,e)=>h(t,e,[4,5,6,7,8,9,10,11]),r=(t,e)=>h(t,e,[8,9,10,11,0,1,2,3]),o=(t,e)=>h(t,e,[0,1,2,3,4,5,6,7]),h=(t,e,l)=>{let r=Math.cos(e*Math.PI/180),o=Math.sin(e*Math.PI/180),h=l.map((e=>t[e]));for(let e=0;e<4;e++)t[l[e+0]]=o*h[e+4]+r*h[e+0],t[l[e+4]]=r*h[e+4]-o*h[e+0]};const a=16;return(h,s)=>{const f=(t,e)=>s[t]>=0?s[t]:e;let i=f(4,5)/10,$=f(5,3)/10,c=f(6,2)/10,n=f(7,6)/10,M=[];M[0]=`hsl(${f(8,0)},100%,${f(a,50)}%)`,M[1]=`hsl(${f(9,0)},100%,${f(a,50)}%)`,M[2]=`hsl(${f(10,0)},100%,${f(a,50)}%)`,M[3]=`hsl(${f(11,0)},100%,${f(a,50)}%)`,M[4]=`hsl(${f(12,0)},100%,${f(a,50)}%)`,M[5]=`hsl(${f(13,0)},100%,${f(a,50)}%)`,M[6]=`hsl(${f(14,0)},100%,${f(17,0)}%)`,M[7]=`hsl(${f(15,0)},100%,${f(17,0)}%)`,M[8]="black";let u=0,m=[],A=[],b=[],w=[],p=Array(29).fill(0).map((()=>[0,0,0,0,0]));if(h.length!==2*p.length)throw new Error("circles num error");let E=()=>{let a=f(0,60)+120+u,s=f(1,45)-45,P=2*f(2,2)+4,d=Math.sin(9*(f(3,0)+u)*Math.PI/180),y=30*d,I=.3*Math.abs(d);u++,t(m,[1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1]),p[0]=[0,0,0,i,0];for(let r=0;r<2;r++){let h=1+r,a=0===r?1:-1;t(A,m),o(A,30*a),l(A,-y*a),e(A,0,-(i+.7*$),0),p[h]=[A[12],A[13],A[14],$,h]}for(let l=0;l<2;l++){let o=3+l,h=0===l?1:-1;t(A,m),r(A,+y),e(A,(i+.5*c)*h,0,0),p[o]=[A[12],A[13],A[14],c,o]}t(A,m),l(A,-30),e(A,0,+(i+.7*n),0),l(A,30),t(b,A),l(b,150);for(let l=0;l<8;l++){let r=l/7;t(w,b),e(w,0,0,-1.333*n*r),p[5+l]=[w[12],w[13],w[14],n*(3-2*r)/3,5]}for(let l=0;l<2;l++){let o=0===l?1:-1;t(b,A),r(b,-15*o),e(b,0,0,-.8*n);for(let r=0;r<8;r++){let o=r/7-.5;t(w,b),e(w,0,.6*n*o,0),p[13+8*l+r]=[w[12],w[13],w[14],n/6,6+l]}}let g=p.reduce(((t,e)=>Math.min(t,e[1]-e[3])),0);p.forEach((t=>{t[1]+=I-g})),(e=>{t(e,[1,0,0,0,0,-1,0,0,0,0,-1.2,-1,0,0,-2.2,0])})(m),e(m,0,0,-P),l(m,s),r(m,a),e(m,0,-1.4,0),p.forEach((l=>{t(A,m),e(A,l[0],l[1],l[2]),l[0]=A[12]/A[15],l[1]=A[13]/A[15],l[2]=A[14]/A[15],l[3]=l[3]/A[15]})),p.sort(((t,e)=>e[2]-t[2]));let k=0;for(let t=0;t<2;t++)p.forEach((e=>{let l=h.item(k++);l.setAttribute("cx",Math.floor(350*(2*e[0]+.5))),l.setAttribute("cy",Math.floor(350*(2*e[1]+.5))),l.setAttribute("r",Math.floor(2*e[3]*350+(0===t?16:0))),l.setAttribute("fill",M[0===t?8:e[4]])}));window.requestAnimationFrame(E)};E()}})();';
}

// ----------------------------------------------------------------
// ----------------------------------------------------------------
// ----------------------------------------------------------------

