//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC1155MetadataURIUpgradeable.sol";
import "./ERC1155Upgradeable.sol";
import "./ECDSA.sol";

import "./RoyalPausableUpgradeable.sol";

//                       THIS LOOKS LIKE WORST CASE SOUNDS
// ╣╬╬╬╬╬╬╣╬╬╣╬╬╣╣╣╣╝╝╛╙╝╣╣╣╬╣╬╬╬╬╣╣╬╬╬╬╬╬╬╬╬╬╬╬╣╬╬╬╬╣╣╬╬╬╬╣╝╨╙╝╣╣╬╣╬╬╬╬╬╬╬╬╬╬╬╬╬▌Γ
// ╣╣╣╣╣╣╣╣╣╝╩ΘM~~_________-~ºΘ╙╩╝╣╣╣╣╣╣╣╣╬╣╣╣╣╣╣╣╣╝╩δM≈~~________~~*╚å╝╝╣╣╣╣╣╣╣╣▌∩
// ╬╬╫╫╫▒▒▒╖─____________________~╖▒▒╫╫╫╬╬╬╬╬╬╣╫╢▒▒,,__________________,,▒▒╢╫╫╬╬╬▌≥
// ╬╬╣╣╣╣╣#╗╗m,,_____________,,╓╗╗╗╣╣╣╣╣╣╬╬╬╬╣╣╣╬▒╗╗╦,_______________,,╔╦╗φ▒╣▓╣╬╬▌░
// ╬╬╬╬╣╣╫╫╢╨╙╙╙╙"_________^"╙╙╙╙╚╢╫╫╣╬╣╬╬╬╬╣╫╫╫╫╢╠╠╙╙╙╙"`________`"╙╙╙╙╠╠╢╫╫╫╫╫╬▌Γ
// ╬╬╬╣╫╢╩²~~____________________~²φ╝╢╫╬╬╬╬╬╬╬╣╬╠░ⁿ~~~________________~~~ⁿ╚╠╠╬╬╬╬▌≥
// ╬╬╬╬╬╣▓▓▓▒╗╗µ╓,__________╓µ╦╗@▒▓▓╣╣╬╬╬╬╬╬╬╣╣▓▓▒▒@#╗╗▄,__________,╓╗╗@@▒▒▒╣╣╣╬╬▌_
// ╬╬╬╬╬╬╬╬╙╙^`_______________``"╙╙╬╬╬╬╬╬╬╬╬╬╬╬╬╠╩╙╙╙¬________________¬╙╙╙╙╠╠╬╬╬╬▌_
// ╬╬╬╬╬╬╬╣▒▒▒"_______________"7▒▒╬╬╣╬╬╬╬╬╬╬╬╬╬╬╬╬╣▒▒`_______________.Γ▒▒╫╫╬╬╬╬╬╬▌_
// ╬╬╬╬╣╣╬▒╗╗▄╓,,____________,,╓▄╗╗╬╣╣╣╬╬╬╬╬╬╬╬╣╣╣▄▄╥╓,______________,╓╖▄▄╣╣╣╬╬╬╬▌_
// ╬╬╬╬╬╣╬╬╩╩╙╙╙└____________╙╙╙╙╠╩╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╢╩╙╙╙└____________└╙╙╙╠╢╢╬╬╬╬╬╬▌_
// ╬╬╬╬╬╬▒▒░____________________`,▒▒╠╬╬╬╬╬╬╬╬╬╬╠╠▒,,,__________________,,,▒╠╠╣╬╬╬▌_
// ╬╬╬╬╬╣╬╣╣▒▄▄╓,____________,╖▄▄φ╣╣╣╬╬╬╬╬╬╬╬╬╣╬╣╬╢▄▄▄╖╓,__________,╓╖▄▄▄╢╣╬╣╬╬╣╬▌_
// ╬╬╬╣╣╣╬╬╩╩╙╙╙╙╙`________"╙╙╙╙╙╩╩╬╣╣╣╬╬╬╬╬╬╬╣╝╩╩╩╩╩╩╙╙╙__________╙╙╙╩╩╩╩╩╩╝╣╬╬╬▌_
// ╬╬╬╬╣╩777_____________________-777╝╢╣╬╬╬╬╬▒╩▒δ---____________________---δ╚╩╬╬╬▌_
// ╬╣╣╢▒QQ^________________________^Q▒╢╢╣╬╬╬╬╠▒░,,________________________,,░▒╠╬╬▌_
// ╬╬╬╬╬╩╩²ⁿ⌐⌐¬¬_____________¬¬¬⌐⌐ⁿª╩╩╬╬╬╬╬╬╬╬╬╩╩╙ªªⁿ¬¬______________¬¬ⁿⁿª╙╩╩╬╬╬╬▌_
// ╬╣╣╣╬╬M7""^__________________^""7#╬╣╣╣╣╬╣╣╝╝╩╩>>.____________________.¬>╚╝╝╢╣╣▌_
// ╬╬╣▒▒▒▒▒``____________________`,Σ▒╢▒╫╬╬╬╬╫▓▒▒▒▒,,,__________________,,,░▒▒▒▓╫╫▌_
// ╬╬╬╬╬╬╬╩╩╨╙5"_____________""╙╙╨╩╩╬╬╬╣╣╬╬╬╬╬╬╝╝╩╨╙╙╙ⁿ¬____________¬ⁿ╙╙╙╨╨╝╝╢╬╬╬▌_
// ╬╬▒▒▒M"ⁿ________________________"7M▒▒╬╬╬╬╢▒▒▒7``______________________``77▒▒▒╬▌_
// ╣╣╬▒QL^__________________________^Q▒╠╫╣╬╣╢▒▄╓─__________________________┌╓╥▒╣╫▌_
// ╬╬╬╬╬╩╙░⌐¬____________________¬ⁿ╙╚╬╬╬╬╬╬╬╬╬╬╬▒░~~____________________~~░╠╬╬╬╬╬▌_
// ╬╬╬╬╩╩δ=¬______________________¬≈φ╩╩╬╬╬╬╬╬╬Åñ""``____________________``""ñÅ╬╬╬▌_
// ╣╣╬▒φQD(_______________________,Ç¿Q╠║╫╣╬╫╢#▒M?^^^____________________`^^?M╠#╢╫▌_
// ╣╫╢╢╨╜╨╜╚╚^^_______________^^╙╚╚╜╨╨╢╢╢╫╣╨╨╨╨╨╨╜╜^____________________^╙╜╨╨╨╨╨╨▌_
// ▒░~~~~~~________________________~~~~~~░╬▒α~~~~__________________________~~~~░▒╡_
// ╢╩╚"σ..._______________________...."╚╚║╬╩╩>»»..¬______________________¬..»»>╚╩╡_
// ▒░░░┬--------_____________--------┬░░░▒╣▒½┬----------____________---------┬┬░▒╡_
// ╣▒▒─~~────~_________________~~─~~~~~┴▒▒╣▒▒┬─────~_____________________─────┬╖▒▌_
// ╣╝φ=¬¬¬¬¬_____________________¬¬¬¬¬¬≈╚╝╬╩φ>>>¬¬¬¬¬__________________¬¬¬¬¬¬>>½╩╡_
// ╝╝╝∞---------_____________----------∞╝╝╣╝δ-----------.__________------------╚╝╡_
// ▒φ²²²--─~~____________________~~--²-²²╖╣▒╓--^``________________________``^--╓φ╡_
// ╬µεε.¬¬__________________________¬..εα╦╬Nεε...__________________________...ε≤A╡_
// ╬░---------._______________..--------░╚╬▒φ--------.._____________...---------▒╡_
// ╬▒φ≥---ⁿⁿ______________________ⁿⁿ---φ╠╠╬╠▒7---ⁿ~______________________`ⁿ---7φ╠▌┐
// ╬╩ε¬¬¬¬¬¬______________________¬¬¬¬¬¬δ╩╬δ≡⌐¬¬¬¬¬______________________¬¬¬¬¬¬≡Å╡ε
// ╬╩═---___________________________----═╬╬▒░═--`__________________________`--═░▒╡░
// ╩7---______________________________--77╬----_______________________________---╡O
// ▒..._______________________________...J╬µε._______________________________,.:µ╡Γ
// ▒----....______________________....---╓╬╕--...._______________________.....---╡"
// ╬▒7^^-----____________________----^^77╩╬╩7º-----______________________-----^7╩╡_
// ╬╦εε=~~__________________________~=;ε≥╦╬≥≡ε==~__________________________~==ε≡φ▌_
// ▒^___________________________________^φ╬ΣJ^^^____________________________^^^2Σ╡_
// ╩».....__________________________.....º╬>»....__________________________....»»╡_
// ▒░,,_______________________________,,░φ╬µ;,,______________________________,,╓φ╡_
// ▒≡.._______________________________...≥╬≤.....__________________________.....:╡_
// ▒░εε.--_________________________---«ε░▒╬εε=-----______________________-----=τε╡_
// ▒ε┬─~~____________________________~~┬╖¥╣εⁿ~─~~─________________________───~─÷¥╡_
// ▒▒¿..______________________________..φφ╣φ≥-~~____________________________~~-φφ╡_
// ╩:..________________________________..≤╬ε..________________________________..≤╡_
// ▒╖----~__________________________----┬▒╣▒-------~____________________~~-----░▒▌_
// ╬Qµ,,,___________________________,,,,¿╠╬MDDµ,.....__________________......¿DD╠╡_
// ╬æprrrr...____________________...r¬rrµÅ╬Ñtrr¬...______________________...¬rrτÑ╡_
// ╬▒≥≈=----_____________________-----≈φφ╠╬▒φ7-----______________________-----7φ╠▌_
// ╬╬µç¬______________________________p╔╠╬╬╠▒L,,,,,______________________,,,,;L▒╠▌_
// ╬b>⌐¬¬¬¬________________________¬¬¬¬⌐ε5╬ε¬¬¬¬¬¬________________________¬¬¬¬¬¬¿╡_
// ╬φ----._________________________.----╓╚╣φ-----,..____________________..,-----╠╡_
// ╬░ƒƒ;;;,________________________,;;;ƒƒ╙╬░░;;;,,________________________,,;;;░░╡_
// ╬▒░;;;,,________________________,~;;░░▒╬░;;,_____________________________.,;;░╡_
// ╬╩╩═-----______________________----=═╩╩╬╩7º----________________________----º7╩▌_
// ▒#╖╓------____________________------╓╖▒╣▒╤------______________________------╤#╡_
// ╣╬╬╣╬▒▒╖╓-___________________.,╔╥▒▒╣╣╣╣╬╣╣╣▒▒▒▄e,____________________,e╥▄╗▒╣╬╣▌_
// ╬╬╫╫╬╬╠╠╙╙`_________________`"╙╙╠╠╬╣╫╫╬╬╬╬╬╬╬▒╠╙╙"_________________`"╙╙╠╠╫╬╬╬╬▌_
// ╬╬╬╬╬╬╬╬╬╬╬▒╦,___________.«▒╫╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣╣╬╣╬╦»____________»╦╣╣╣╣╣╬╬╬╬╬╬▌_
// ╬╬╬╬╬╝╝╧╛--_________________--:≈╝╝╣╬╬╬╬╬╬╬╬╬╣╩╧═=--________________--:=╧╝╢╬╬╬╬▌_
// ╬╬╬╬╣╣╬▒▒QL,________________,LE▒╬╣╬╣╬╬╬╬╬╬╬╬╣╣╣▒▄L,________________,╓▄▒╢╣╣╬╬╬╬▌_
// ╬╬╬╬╬╬╬╣╣╨╜╜~`___________``└╜╨╨╫╬╬╬╬╬╬╬╬╬╬╬╬╬╬╫╫╢╨┴~`____________`└╙╜╢╫╫╬╬╬╬╬╬▌_
// ╬╬╬╬╫╣╢╠▒,,,________________,,╓▒╠╫╫╫╬╬╬╬╬╬╬╬╬╬▒▒,,__________________,,╠╠╬╫╬╬╬╬▌_
// ╣╫╫╫╫╫╢╢╚╙`_________________^"╙╠╢╢╫╫╫╫╫╬╫╫╫╣╫╬╝╚╙^^________________`"╙╙╠╬╫╫╫╫╫▌_
// ╬╬╬╬╬╬╬╬╬╣▓▒▒⌐___________¬ⁿ▒▒╣╣╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣▓▓▒╗ε~__________~«╗▒╣▓╬╬╬╬╬╬╬╬▌_
// ╬╬╬╬╬╩╙╙╙└`__________________└╙╙╙╙╠╬╫╬╬╬╬╬╬╩╠╚╙╙`_____________________╙╙╚╠╩╣╣╬▌Γ
// ╬╬╬╬╣╬╬╬▄╓___________________,╓▄╬╬╣╬╬╬╬╬╬╬╬╬╬╬╦φε,__________________,rφ╦╬╬╬╬╬╬▌░
// ╬╬╬╬╬╬╬╬╬╬╫╢▒¬¬__________¬ñ╜╫╫╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣▒▒`____________`▒╢╣╬╬╬╬╬╬╬╬╬▌▒
// ╣╣╬▒▒╙╙└________________________└╙╙╚╠╣╫╣╬▒╩╙╙└__________________________└╙╙╩╠╬▌∩
// ╬╬╬╠╦ε___________________________.≤╠╠╬╬╬╠╠╠Lεε¬¬______________________¬¬¬ε≤╠╠╠▌Γ
// ╣▓▒▒▒▒▒░~~____________________~~φ▒▒▒▒▓╣╬╣▒▒▒▒½┬░______________________;╓╖▒▒▒▒╣▌┘
// ╣╬╢╢╬╦Q¬_______________________¬ƒQ╠╠╢╢╣╣╣╣╠▄▄╓,________________________,╓▄▒║╢╣▌_
// ╬╣╬╬φφ⌂∩^^____________________^,⌂φφ╬╬╣╣╬╬╬╬╩Mε.________________________.≤≥╩╠╬╬▌_
// ╣╫╫╫╫╫▒▒▒Mƒⁿ_______________;ⁿƒ@▒▒╢╫╫╫╫╫╬╬╬╬╬╫╢▒▒WSº^______________^º≥≥▒╢╢╢╫╬╬╬▌_
// ╬╬╩╚,...________________________..,╚╚╠╬╬╬╬▒╠░.__________________________.│╠╠╬╬▌_
// ╬╬╩▒░¬¬__________________________¬¬╙╩╩╬╬╣╠▒░⌐¬__________________________¬¬░▒║╫▌_
// ╬╣╬╢▒╠▒--_____________________.-░▒╠▒╫╫╣╬╬╣▒╩╩----____________________----╚╠╢╫╬▌_
// ╬╬╬╬╠MM∩¬_____________________¬"≤M╬╠╬╬╣╣╬╬╠MN≥ε¬______________________'ε≤NÆ╠╬╬▌_
// ╬╠╠▒┴─,_________________________,──╙╠╠╠╬╬╠▒░,,__________________________,,░╠╠╬▌_
// ╬╣╣╣╣#╗╗╤╓─__________________~╔╤╗#╝╣╣╣╬╬╬╬╣╬╢╗╤╤--__________________--═╗╗╢╢╣╬╬▌_
// ╬ßß5"^^^________________________^"^"ßß╙╬╙TT^?^^^^^^________________^^^^^^???T╙╡_
// ▒░░~~______________________________~░░▒╣▒░░~______________________________~~░▒▒_
// ╬ñε¬________________________________¬ε╠╬ε>....__________________________.....≡╡_
// ╬╩░░..___________________________,..µ╠╩╣▒░...,__________________________....└░╡_
// ╬╨Γ...____________________________..≥╙╢╣▒⌂._______________________________..≤▒▌_
// ╬╬Å&».._________________________...≤&╩╠╬╬▒Γ^...________________________...^7╚╠╡_
// ╬.....____________________________....!╬≤..________________________________..≤╡_
// ▒▒░░_______________________________~░░▒╢▒┴┬~~_____________________________~┬²▒╡_
// ▒bε¬________________________________¬rΣ╬Ür.________________________________.r≤╡_
// ╬▒φ░,,,,,______________________,,,,││φ╠╣▒φ,,,,._________________________,,,,φ║╡_
// ╣▒,.________________________________,7╢╣╩½>-______________________________-(╚╚▌_
// ╬▒░_________________________________,Γ╠╬▒L^^______________________________^^░╚▌_
// ╬╙⌐¬¬¬¬¬_______________________¬¬¬¬¬¬╙╜╬b5¬¬¬¬¬¬______________________¬¬¬¬¬"5@╡_
// ▒(^__________________________________(7╬^____________________________________^╡_
// ▒░░__________________________________░░╬░____________________________________░╡_
// ╬δ░└_______________________________^└δ╠╬δΓ^________________________________.Γδ╡_
// ╬ƒ⌐__________________________________ƒX╬D¬__________________________________,D╡_
// ╠░░--______________________________-░░╠╬░░-`_______________________________-░░╡_
// ╬░___________________________________,,╬╠,__________________________________,╠╡_
// ╩∩-__________________________________-ª╬ƒ¬__________________________________¬ƒ╡_
// ▒┘`````__________________________````└┴╢░````____________________________````░╡ε
// ╬LL__________________________________IÑ╬≥____________________________________,▒░
// ╬.____________________________________░╬∩¬__________________________________¬ª╡╕
// ╬░``_______________________________^``░╬░`__________________________________`│╡░
// ╬▒▒7-______________________________-7░▒╬▒≥--______________________________--º≥▒Γ
// ▒────~____________________________~───~╣░──~~~___________________________~~~─░╡╕
// ▒Γ````____________________________````Γ╬Γ.`````________________________`````.»╡_
// ╬▒░"^`____________________________`""░╠╬▒▒░""____________________________"""▒╠▌_
// ╬░^~_______________________________~~²░╣▒░░~~~~~_______________________~~~~░░▒▌_
// ╬ñl7..____________________________.^7l╠╬ÿ?^^^^^________________________^^^^^?7╡_
// ╠░,,________________________________,░░╬░░__________________________________'░╡_
// ▒--~─~____________________________───-╔╣½---~~__________________________~~---≈╡_
// ╬Σ^^^^`^________________________^^^^^^Σ╬ΣL^^^^__________________________^^^^L2╡_
// ╬"ƒ¬"``__________________________``¬¬ƒÿ╬▒"""``__________________________``"¬"ÿ▒_
// ▒--~~~~_________________________-~`~~-φ╬φ░~~`~__________________________~~~~░½▌_
// ╬ΣD..______________________________.└3Σ╬▒L^^______________________________^.│╠▒_
// ╣▒##αεε...____________________...--α##╣╬╣▒#αα...______________________...»»#▒╣▌_
// ╬▒▒▒╓,,,_______________________,,,,╓▒║╫╬╬╬▒½,,,.-____________________-.,,,½▒╠╣▌_
// ╬╬╫╢▒░^^^_____________________`^^?░║╢╣╬╬╬╫╢╠░L^_______________________``(░╠╢╢╬▌_
// ╬╣╢▒▒▒""```"_______________""```""▒▒▒╢╣╬╣╢▒▒▒""``""^_____________`^""``""å▒▒╢╣▌_
// ╬╬╬╬╬╠╓77```_______________```777╠╠╬╬╬╬╬╬╬╬╬╬▒77`-``______________``-`77╠╠╬╬╬╣▌_
// ╬╬╣╢╢╩░░¬¬¬_________________¬¬¬¬░╠╪╢╢╣╬╬╬╣╬╢╪╩░¬¬¬¬________________¬¬¬¬░╠╪╢╢╬╬▌_
// ╬╣╫▒▒▒▒∩"""^^^`^________^^^^^"""å▒▒▒╣╫╬╬╬╫▒▒▒▒▒"""^^^``________`^^^^"""▐▒▒▒║╫╬▌_
// ╬╬╬╬╬╬╠?..._________________....3╠╬╬╬╬╬╬╬╬╬╬╬╠▒^...________________...`3╠╬╬╬╬╬▌_
// ╬╬╬╢╝╝╝⌐¬¬¬_________________¬¬¬¬╙╝╝╢╢╬╬╬╬╬╢╝╝╝░¬¬¬__________________¬¬¬j╝╝╝╢╬╬▌_
// ╬╬╬▒▒▒ΣΓ"7^^^^___________`^^^^""╚▒▒▒╬╣╬╬╬╣▒▒▒▒Γ"7^^^^^__________^^^^^^"7▒▒▒▒╣╬▌_
// ╬╬╬╬╠╠╠µJ^^^^_____________`^^^^J╠╠╠╬╬╬╬╬╬╬╬╬╠╬GJ^^^`______________^^^^Jφ╬╠╠╬╬╬▌_
// ╬╬╬╣╝╝▒░░░~'________________~░░░╚▒╝╝╣╬╬╬╬╣╣╝╝╝░░░░~________________~░░░╙╚╝╝╣╣╬▌_
// ╣╣╣▒▒▒▒▄Nºººº÷─__________─ºººººSÉ▄╢╢╢╣╣╬╣╣╢╢▒▒▄SNNºº-~__________ⁿ-ººNNS▒▒╢╢╢╣╣▌_
// ╬╬╬╬╬╬╬╬╬╣╣▒▒░~__________:5▒╣╬╣╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣╣▒▒φ,,________.,╓▒╢╣╣╬╬╬╬╬╬╬╬▌_
// ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣▄,___,╓╢╣╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣▒╓.__.╓@╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▌_
// ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓▒╣╣╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▒å╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▌_
//                                     by 3LAU

/**
 @dev Implementation of Royal.io LDA using ERC-1155
 See https://eips.ethereum.org/EIPS/eip-1155

 The `ldaID`s used in this contract is a synthetic ID. The first 128 bits are the
 `tierID` and the last 128 bits are the `tokenID`. This effectively means that:
 `ldaID = (tierID << 128) + tokenID`
 */
contract Royal1155LDA is
    ERC1155Upgradeable,
    RoyalPausableUpgradeable
{
    // TODO: Decide if this pattern is better, or if I should use 
    event NewTier(uint128 indexed tierID);
    event TierExhausted(uint128 indexed tierID);

    uint256 constant UPPER_ISSUANCE_ID_MASK = uint256(type(uint128).max) << 128;
    uint256 constant LOWER_TOKEN_ID_MASK = uint256(type(uint128).max);

    string _contractMetadataURI;

    // (tierID) => max supply for this tier
    mapping(uint128 => uint256) private _tierMaxSupply;

    // (tierID) => current supply for this tier. NOTE: See also the comment below _ldasForTier.
    mapping(uint128 => uint256) private _tierCurrentSupply;


    // MAPPINGS FOR MAINTAINING ISSUANCE_ID => LIST OF ADDRESSES HOLDING TOKENS (with repeats)
    // NOTE: These structures allow to enumerate the ldaID[] corresponding to a tierID. The 
    //       addresses must then be looked up from _owners.
    // TODO: Move this into a library or struct for both code cleanliness & savings on deploy

    /// @notice (ldaID) => owner's address
    mapping(uint256 => address) private _owners;

    /** @notice (`tierID`) => mapping from `ldaIndexForThisTier` [0..n] (where `n` is the # of LDAs 
     *  associated with this `tierID`). to the `ldaID`. This effectively acts as a map to
     *  a list of ldaIDs for a given tierID.
     *
     *  NOTE: The `ldaIndexForThisTier` is the value stored in the _tierCurrentSupply map.
    */ 
    mapping(uint128 => mapping(uint256 => uint256)) private _ldasForTier;

    // (ldaID) => ldaIndexForThisTier this is only required in order to support remove LDAs from _ldasForTier
    mapping(uint256 => uint256) _ldaIndexesForTier;

    // To prevent duplication of state, we will re-use `_tierCurrentSupply` to act as the index. This means 
    // that if we burn any tokens, then we need to decrement this number. 

    // 3lau.eth address
    address public constant signer = 0xD2aff66959ee0E6F92EE02D741071DDB5084Bebb;
    
    // keccak256 Hash of the Song .wav file
    bytes32 public constant songHash = 0x5acbdb71da23246df6fd982a85644e58b753f822dce6168547baa5e0edb74899;
    
    // 3lau.eth signature of the song hash 
    bytes public constant signedSongHash = "0x1626eb2731116e22d9724c0ac48921bb59f7f740bfd93b46c8ca8874896f051c18517fc4c8f4dcd1a183274a897286bca8214c8ac3e18499b547100ad4f50a371c";
    
    function verifySignature(bytes memory _signedSongHash) public pure returns (bool){
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(songHash);
        address messageSigner = ECDSA.recover(messageHash, _signedSongHash);
        return messageSigner == signer;
    }

    function initialize() public initializer {
        __RoyalPausableUpgradeable_init();
        // Pointed to Contract Metadata V1.0
        __ERC1155_init("https://royal-io.mypinata.cloud/ipfs/QmSvvcSApos8wZoQ5aZVL2NS8VqMRTr413kdracgMP1e7N/{id}.json");
        // Pointed to Contract Metadata V3
        _contractMetadataURI = "https://royal-io.mypinata.cloud/ipfs/QmQbyLYAdfxDM2CCg8ci1VrgHTAQDu9BpdpFh3TFUMsixA";
    }

    function updateTokenURI(string calldata newURI) 
        public
        onlyOwner
    {
        _setURI(newURI);
    }

    function contractURI() public view returns (string memory) {
        return _contractMetadataURI;
    }

    function updateContractMetadataURI(string memory newURI) public onlyOwner {
        _contractMetadataURI = newURI;
    }

    /// @dev Check if given tier is currently mintable
    function mintable(uint128 tierID) external view returns (bool) {
        return _tierCurrentSupply[tierID] < _tierMaxSupply[tierID] && this.tierExists(tierID);
    }

    /// @dev Has this tier been initialized?
    function tierExists(uint128 tierID) external view returns (bool) {
        // Check that the map has a set value
        return _tierMaxSupply[tierID] != 0;
    }

    /// @dev Has the given LDA been minted?
    function exists(uint256 ldaID) external view returns (bool) {
        return _owners[ldaID] != address(0);
    }

    /// @dev What address owns the given ldaID?
    function ownerOf(uint256 ldaID) external view returns (address) {
        require(_owners[ldaID] != address(0), "LDA DNE");
        return _owners[ldaID];
    }

    /**
     @dev Create an Tier of an LDA. In order for an LDA to be minted, it must 
     belong to a valid Tier that has not yet reached it's max supply. 
     */
    function createTier(uint128 tierID, uint256 maxSupply) 
        external 
        onlyOwner
    {
        require(!this.tierExists(tierID), "Tier already exists");
        require(tierID != 0 && maxSupply >= 1, "Invalid tier definition");
        require(_tierCurrentSupply[tierID] == 0 && _tierMaxSupply[tierID] == 0, "Tier exists");
        
        _tierMaxSupply[tierID] = maxSupply;

        emit NewTier(tierID);
        // NOTE: Default value of current supply is already set to be 0
    }

    // TODO: (Maybe) implement a bulkMintLDAsToOwner as an optimization to bulk mint a shopping cart. 
    //       LDAs from different tiers can be minted together. 

    function mintLDAToOwner(address owner, uint256 ldaID, bytes calldata data)
        public
        onlyOwner
    {
        require(_owners[ldaID] == address(0), "LDA already minted");
        (uint128 tierID,) = _decomposeLDA_ID(ldaID);
        
        // NOTE: This check also implicitly checks that the tier exists as mintable()
        //       is a stricter requirement than exists(). 
        require(this.mintable(tierID), "Tier not mintable");
        // NOTE: Should we include a semaphore 
        // require(_tierCurrentSupply[tierID] < _tierMaxSupply[tierID], "Cannot mint anymore of this tier");

        // Update current supply before minting to prevent reentrancy attacks
        _tierCurrentSupply[tierID] += 1;
        _mint(owner, ldaID, 1, data);

        // Emit the big events
        if (_tierCurrentSupply[tierID] == _tierMaxSupply[tierID]) {
            emit TierExhausted(tierID);
        }
    }

    /**
    @dev Decompose a raw ldaID into it's two composite parts
     */
    function _decomposeLDA_ID(
        uint256 ldaID
    ) internal pure virtual returns (uint128 tierID, uint128 tokenID) {
        tierID = uint128(ldaID >> 128);
        tokenID = uint128(ldaID & LOWER_TOKEN_ID_MASK);

        // NOTE: Not sure if we want to enforce tokenIDs > 0 
        require(tierID != 0 || tokenID != 0, "Invalid ldaID");
    }

    // HOOK OVERRIDES 
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        // Iterate over all LDAs being transferred
        for(uint a; a < ids.length; a++) {
            // Decompose out here as an optimization
            (uint128 tierID,) = _decomposeLDA_ID(ids[a]);
            if (from == address(0)) {
                // This is a mint operation
                // Add this LDA to the `to` address state
                _addTokenToTierTracking(to, ids[a], tierID);

            } else if (from != to) {
                // If this is a transfer to a different address.
                _owners[ids[a]] = to;
            }

            if (to == address(0)) {
                // Remove LDA from being associated with its 
                // TODO: Move this to burn transaction state
                _removeLDAFromTierTracking(from, ids[a], tierID);
            }
        }
    }

    // ENUMERABLE helper functions
    // TODO: I don't think this function signature is quite correct. Needs improvement.
    function _addTokenToTierTracking(address to, uint256 ldaID, uint128 tierID) private {
        // TODO: Figure out if this is right because these numbers could be changing during a mint
        uint256 ldaIndexForThisTier = _tierCurrentSupply[tierID];
        _ldasForTier[tierID][ldaIndexForThisTier] = ldaID;

        // Track where this ldaID is in the "list"
        _ldaIndexesForTier[ldaID] = ldaIndexForThisTier;

        _owners[ldaID] = to;
    }

    /** 
     * @dev This is a sexy little trick I pulled from the OZ implementation of {ERC721Enumerable-_removeTokenFromOwnerEnumeration}.
     * See More: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/6f23efa97056e643cefceedf86fdf1206b6840fb/contracts/token/ERC721/extensions/ERC721Enumerable.sol#L118
     */
    function _removeLDAFromTierTracking(address from, uint256 ldaID, uint128 tierID) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastLDAIndex = _tierCurrentSupply[tierID] - 1;
        uint256 tokenIndex = _ldaIndexesForTier[ldaID];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastLDAIndex) {
            uint256 lastLDA_ID = _ldasForTier[tierID][lastLDAIndex];

            _ldasForTier[tierID][tokenIndex] = lastLDA_ID; // Move the last LDA to the slot of the to-delete LDA
            _ldaIndexesForTier[lastLDA_ID] = tokenIndex; // Update the moved LDA's index

        }
        // This also deletes the contents at the last position of the array
        delete _ldaIndexesForTier[ldaID];
        delete _ldasForTier[tierID][lastLDAIndex];

        _owners[ldaID] = from;
    }
}