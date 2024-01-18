
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Calladita Sartoshi
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                             //
//                                                                                                                                                             //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnvh#8&*%Bnnnnnxddddoknnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnwW&W@$$$@@&qoaaaaaaao#%WoZmCnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnYLW@%##B%%$$@@%WMaaa8%%%%%%BWW###aao8&Qxnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnxzqo%@@$@B8W###@@$@crxvXXu[     1OmZbW%88%%%%%8Jnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnp&B@@@@@$$$&####@$$$                    .`OaM%%%%B8qnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnncM%B@%Wtz@88%####8@$$#                         '+vBBBB8%onnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnC8B@Bb(  a#&##%@&##@$$Y                              w8B8%8Zxnnnnnnnnnnnnnnnnnnnnnnnnxvnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnYW@BBW1    *#@#@@@8#8@$$f                               idaaaa%WYunnnnnnnnnnnnnnnnnnnO#B%Ynnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnno%@@Bh.    ,##@@@$B##W@$$)                                 .Caaa&*oUnnnnnnnnnnnnnnnnOo*%BBMunnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnno8B@@B;      i&#M%@@B##&@$$)                                   'LoMB8obnnnnnnnnnnnnnnnnna%%BWunnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnXWB@@Bq^       C@8BB#%%#*M@$Wl                                     "m8BB&oXnnnnnnnnnnnnnnJLMW@pnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnUW@B%&Y        ;Z%@BBW@B&8B%$o                                        ;a%M*Onnnnnnnnnnnnnnnno8@qnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnvh@$@#W^         <#%@@@W@W#8@%$o                                          &B%%nnnnnnnnnnnnnnnnaBBwnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#B@B*c           ~&$@B%@@@BWB@$8bp?                                       UoW%dxnnnnnnnnnnnnnn8BBqnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnpBB#%}          l08%B$@@$@B%B@@$@%%B%Jz.                                   IbaW%Lnnnnnnnnnnnnnu%BBOnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnW%Wan         ;mW$$@%%@WW@B&&M#W8@@%BB%hCl                                  /oM%annnnnnnnnnnnnJ%@@Cnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnMB&a!        lhB@@8M8@@@@@@8M@8#**%@$B@%8br.                                 08%8cnnnnnnnnnnnnL%BBznnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnn%B&a        _k$$BMW@$B#&$@%%%%B######@$@B%bd.                                :k%&bnnnnnnnnnnnnO%B%xnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnn%BWa        bB$$#%$@@@@@M#%@BB@W#####M@@$B@%b/                                z#Bacnnnnnnnnnnnw%BMrnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnc%BWh       ?a@$B%$$@@@@$%@B%@B@%######8@$@B@@of              .jvf     i".     X%B%annnnnnnnnnnwBBannnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnn*%@&a       Oo$$@$$$@@%@@@8@@&%@@#######8$$@@@Wb|            a@@$$Wl  m@@$p    `W@B*cnnnnnnnnnnwBBonnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnn]%@Bq       0M@$$$@@@%%@@@@@@@@@@B#####B@B&%@@*b/            h$$@@M! }@$$$a,    #@B#nnnnnnnnnnnmBB*nnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnn8@B(       k@@$$%@$BB@@@@@@@@@$@@WM@B#MB$8%@@Md              |Bh_.   _%Bq.    >MB@MnnnnnnnnnnnZBB%nnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnXB@8"       Q&B$$B@@@@@@@@@@@@@$@B%&#@88$$BB$@B,                                oW%%qnnnnnnnnnnZBB8nnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnO@@B"       0#B$@$@BB@@@@@@@@@@@@@&M%B@$$$@@@@a                                 x&8#knnnnnnnnnnnB%Bvnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnp@$B"      'Ooo@$8@@$@@@@@@@@@@@@BM$@@@$$$@@@Bt                                 #&B#bnnnnnnnnnnnLM8mnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnoB@%B       Zo%@$$$@@@@@@@@@@@@@@$@$@@$$@@@%%bt                                 oBB%&CnnnnnnnnnnnMBwnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnn%BB8*"      /8W%$@8WBB@%$@@@@B@@&%$$$@B@@@BO                                  co**%bnnnnnnnnnnnnxbZnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnb*aBBMh        nbW$$$$$$@$@B$$$8$$%M%@@@@%%U                                  .Y*M&Mxnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnmJnhBB8Z`       ;q%@@@@B%%@@&*####*&@@@B%W-              ?<`                  !#%&&Cnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnh%B%&`        XkkBB@@@#B@BBB@8a@@@%al               n@$$@$z.             ^Y8%%xnnnuvvvz*#&@@@8oQnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnua%@%M:        'cddkk8%@B%%%B%8h[ '                '$$$$$$$@aC   ![rYb&$$@B%@%8%B@@@B@$$$$$$$$B0nnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnYh&@BB8q.          l+'                             ^|@$$$$$$$$$$$$$$$$@@%%B%@@@BB@@%%8pQQJUUaLnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnxp#B8&MdI                                             lzd@$$$$$@@$@@BBBBBWbxnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnna%BB%8#"                                                        _&B@@8dQnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnCM@BW&Wo-                                                    <ha8@B8Jnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnJa#%B&@B@@%&x'                                              )O&W8BBhCcnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnC&B8%88%M8&&8@@BMq_                                         Ita8BBBBbunnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnZ%%o#8BW8*8#Jb%W8@@Mat`                                   >va*%@@%%mxnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnC#B##%B@%o**oYnnb#BBB%*oh?`.                         {h**aa#%BBaknnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnUW@B%W@&WaW*#Lnnnud*8BBB#aaa[                     j&%%%%%oaUXznnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn0@BB*8%8W*a*qnnnnnnn0*#oaa#8@@B&M*ahc1 ]ULLQhM8B@B8%%dCnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnpB@@BB8%**aaXnnnnnnnnnLZdaooWW8@B@@@@B%#%%%%BB8dOnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnk@@8%B@ZUnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnkBBBB%%%*aaavnnnnnnnnnnnnnnnnObYOddaoBB@o88#MCnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnqaOo_~!,hvLWbczccCoaoao#%@BB    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnno%#8%B%%*aakcnnnnnnnnnnnnnnnnnnnnnnnZ#%8*8munnnnnnnnnnnnnnnnnnnnnnnnzh0nnnvpoakhkkhhhhBQwcW{;&!d%8BBBB8%%88B@BBB%    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnw@WoBB8%o8adnnnnnnnnnnnnnnnnnnnnnnnnno8B%onnnnnnnnnnnnnnnnnnnnnnnYM%BB%M88&MM##8%%B%mWhax{r&&#u%0%%88%%%%&***hmU    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn*BwWB&W*aW#qnnnnnnnnnnnnnnnnnnnnnnnnXaB@8oXnnnnnnnnnnnnnnnnnxJq%%B@@BB8%BBBB%BB8M&8&m0!c@8uX!cWQuxnrnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnwB8#B*&oa&MXnnnnnnnnnnnnnnnnnnnnnnnnO8B@B%JnnnnnnnnnnnnnnXh@@@@@B8%BB8oqpuxrnnnnnnYBrbC1)YUxqoZnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn*B%#B#&*%8*nnnnnnnnnnnnnnnnnnnnnnnnnr&@BB%Mvunnnnnnnnno%B@$@B%#WahbnnnnnnnnnnnnnnnnUBB%%B%vnnnnnnnnnnnnnnunnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn#B8%8&W&88#vnnnnnnnnnnnnnnnnnnnnnnnnz8%8@@&aa0nnnJ*%B@B@B%&*aaCcnnnnnnnnnnnnnnnnnnnnnjnnUpwZYxncqpdka*&8&8BB    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnY8B%%W8MBW&pnnnnnnnnnnnnnnnnnnnnnnnnnp#aoM#W&MoWBB@@@@@8#aaCvnnnnnu0ZZOWMao#MMMMW&%BB%%BBBBBBBBB@BBBBBBB@@BB    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnqBBW8%%8%M*qnnnnnnnnnnnnnnnnnnnnnnnnLo#&a%B%@@$@BBBB&#*o00OM%%%%%BBBB@BBB8M&%%%B@B@@B%%%8%BBB%BB%%#bkpvnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnW88&oo8B%8ounnnnnnnnnnnnnnnnnnnnnnnnnQ888MB@B@$BBB@@@@@@@@@@@@@@@@@@@BB8o*M%B@BB%&&M###opnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnd*&B*o*@B%Cnnnnnnnnnnnnnnnnnnnnnnnnnnuo*%%8B@Bo*BBB%%%%%%8W#*oooo*WaoaoodXvvnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnQaM%Ma8B@BqnnnnnnnnnnnnnnnnnnnnnnnnnnnUo88M8BB@B%W#*888%%%%%W*M0UUunnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnOaMB8*%BB@pnnnnnnnnnnnnnnnnnnnnnnnnnnnnLaa*%B@@@@@BB8W0unnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnpaoW8BBB%@&LnnnnnnnnnnnnnnnnnnnnnnnnnnnnXba#8%%B@@@@%%%8*Ynnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnYaa#B%@@BBBBonnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnno&%%%BB@@%#B%%WCnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnc#B%*BBBBBBannnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnXdao*8%B@BBB88BMhpxnnnnnnnnnnnnnnnnnnnnnnnnnnnnrxnknnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn8@W#@BBB8B*xnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnXOaoM%%%B@@8MoM8MMwnnnnnnnnnnnnCbJppZnnwYaUwOLLZnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnzWBWk%B@BB@qnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnzwaaM8%B@@@%8M8%%8oaLJxnnnnnnnnnnnnnnnnnnnnnnnnnn    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnkB%oW%@%%BknnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnkaoM8%B@$$B@B%@B%%%%aOvnnnnnnnnnnnnnnnnnnnnnn    //
//                                                                                                                                                             //
//                                                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CDST is ERC721Creator {
    constructor() ERC721Creator("Calladita Sartoshi", "CDST") {}
}
