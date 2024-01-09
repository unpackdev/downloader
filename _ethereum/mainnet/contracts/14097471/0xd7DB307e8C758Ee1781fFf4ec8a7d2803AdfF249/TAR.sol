
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TRASH à la Revolt
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                  //
//                                                                                                                                  //
//    DECLARATION OF TRASH DEPENDENCE                                                                                               //
//                                                                                                                                  //
//    On Ethereum, January 28, 2022                                                                                                 //
//                                                                                                                                  //
//    The unanimous Declaration of this #RARIGANG Anarchy, When in the Course of historical events, it becomes necessary            //
//    for one people to strengthen the creative bands which have connected them with a certain symbolic entity, and to              //
//    assume among the powers of the earth, the eternal and unhindered desire to collect the artistic wonders of which              //
//    the Laws of Nature and Blockchain entitle them, a decent respect to the opinions of mankind requires that they should         //
//    declare the causes which impel them to Trash.                                                                                 //
//                                                                                                                                  //
//    We hold these truths to be self-evident, that not all #TRASHART is created equal, that it is saturated by its Creator         //
//    with certain alienesque and infinitely-varied visual anomalies, that among these are Toters, Potatoes, Trash Bags,            //
//    Rats, Red-Lipped Frogs, Golden Arches, Glitched Thought-Adventures, and the pursuit of Trashiness. That to secure             //
//    these ocular fantasies, Trash Directorates are instituted among Artists, deriving their just powers from the consent          //
//    of the governed, That whenever any Form of Bond to any form of #TRASHART becomes so cohesive that separation of such          //
//    would prove destructive of these ends, it is the Right, Duty, and Responsibility of the Trash Artists to seek eternal         //
//    preservation of such Bond, and under Oath swear never to alter or to abolish it, and to institute a new Directorate,          //
//    laying its foundation on such principles and organizing its powers in such form, as to them shall seem most likely to         //
//    eternalize the Safety of the Bond between Artist and Trash, certifying Happiness permanence. Prudence, indeed, will           //
//    dictate that Governments long established should not be changed for light and transient causes; All experience hath           //
//    sh0wn, that Artists will not be disposed to suffer in absence of Trash, regardless whether such evils might be                //
//    sufferable, and will determinedly, and if necessary, forcefully, right themselves by instituting the permanence of            //
//    the Trash bond to which they are naturally and rightfully drawn. When a long train of flagrant abuses and usurpations,        //
//    pursuing invariably the same desires, evinces a design to reduce them under despotic Absolutism, it is their right, it        //
//    is their duty, to throw off such Government, and to appoint themselves as Custodians of their future security. The            //
//    patient sufferance of these Artists shall not be tolerated; and such is now the necessity which constrains them to            //
//    subdue the antiquated state of mind. The history of the Trash-destitute is a history of repeated injuries and usurpations,    //
//    all having in direct object the establishment of a Tyranny over #TRASHART. Let the necessary Trash Dependence be frankly      //
//    demonstrated henceforth to a candid world through a gift of cognition, whereas to write the following stimuli to the          //
//    public record:                                                                                                                //
//                                                                                                                                  //
//    That powers of old have refused to Assent to the Rise of #TRASHART most wholesome and necessary for the public good.          //
//                                                                                                                                  //
//    That powers of old have waged futile efforts forbidding Trash Artists to mathematically preserve memetic prophecy and         //
//    recollection of immediate and pressing importance, while suspended in their belief that influential Assent should be          //
//    obtained; and when so attained, the unfairly determined "insignificant" lacking such obtainment shall be utterly              //
//    neglected and found wanton.                                                                                                   //
//                                                                                                                                  //
//    That powers of old have refused to acknowledge and accede to due recognition of legendary Trash Artists, unless those         //
//    people would relinquish their right on the Bonds we so seek to preserve, at the mercy of the so-be-it-called Crypto           //
//    Space, a right inestimable to them and formidable to tyrants only.                                                            //
//                                                                                                                                  //
//    That powers of old have called together unfit conference at places unusual, uncomfortable, and distant from the               //
//    depository of their rightful occurrence, for the sole purpose of fatiguing them into laying their arms and submitting         //
//    to such measures by way of social destruction and digital banishment, and by way of terror upon the Trash Artists of          //
//    purpose to eat out their substance.                                                                                           //
//                                                                                                                                  //
//    That powers of old have dissolved Trash Representation repeatedly, for opposing with humanly firmness their invasions         //
//    on the rights of the Trash Artists.                                                                                           //
//                                                                                                                                  //
//    That powers of old have contrived with desire to make the "Decentralized" dependent on their Will alone, intentful of         //
//    enrichment of Account and satisfaction of Belly, with regard nary for the Trash Artists.                                      //
//                                                                                                                                  //
//    That powers of old have refused for a long time, after such dissolutions, to stand down from barring others to rise;          //
//    whereby the Trash Directorate powers, fully capable of total Annihilation of presenters of Offense, shall be returned         //
//    to the Trash Artists at large for their exercise; #TRASHART remaining in the meantime exposed to all the dangers of           //
//    invasion from without, and convulsions within.                                                                                //
//                                                                                                                                  //
//    That powers of old have endeavored to prevent the population of the Ethereum Blockchain by #TRASHART; for that purpose        //
//    obstructing the Free Will of Minting rightfully due all who exist; refusing to pass others to discourage and stamp out        //
//    accelerating evolution, and raising the stimulus directly to follow of new Appropriations of Platform.                        //
//                                                                                                                                  //
//    That powers of old have obstructed the Protection of Trash Dependence, by their unjustly Assent to the New Platform of        //
//    Revolution, so-be-it-called Rarible, under guise of Peace and goodwill; but for, in truth, not but to further their           //
//    lustful advance toward the conquest of great Power and Currency.                                                              //
//                                                                                                                                  //
//    The powers of old have affected to siphon the Rari Reserves so allocated to the Trash Artists; and so it be known that        //
//    they have conspired to launder their habits of trade by way of digital falsehoods unfitting to the intended recipient,        //
//    and that they have all but officially declared warfare on the Trash Artists, and that by way of social manipulation,          //
//    extortion, and bribery, direct and otherwise, have appointed themselves independent of and superior to the Civil power.       //
//                                                                                                                                  //
//    The Trash Artists have embraced a state of open platform, fully recognizing the oppressive state of affairs therewithout,     //
//    with great care, desire, and fortitude, so as to bestow the right of Free Expression, and the right to Abstract Chaos         //
//    generation, and the right to the general Pursuit of Trashiness, lest the Artists be gavaged with sufferance beyond a          //
//    level worthy of Disruption of Peace and coordinated uprising; so that they may be free to thrive in a State of full           //
//    #TRASHART immersion.                                                                                                          //
//                                                                                                                                  //
//    We have warned that attempts, however futile, to extend an unwarrantable jurisdiction over #TRASHART would end only with      //
//    inevitable revolution and the subsequent rise to power of Trash. We have appealed to their native justice and                 //
//    magnanimity, in such seeking to provide a deeply personal understanding of the Trash Effect, so defined as a multi            //
//    powerful force, the creation from which it originates a transcendence of le domaine physique conjured by the ties of our      //
//    common kindred to disavow these usurpations. They have been deaf in all manner to the voice of rightful expression and of     //
//    consanguinity. We must, therefore, acquiesce in the necessity to hold them accountable, and to mourn in victorious            //
//    laughter as we watch the dumpster fire illuminate the entropic night above us, yet owing a duty to the rest of humankind,     //
//    Enemies in War, in Peace Friends.                                                                                             //
//                                                                                                                                  //
//    We, therefore, the Trash Artists, in General Congress, Assembled, appealing to the Supreme Will of the People for the         //
//    rectitude of our intentions, do, in the Name, and by the Sanctity of Trash, solemnly publish and declare, that all Trash      //
//    will bask in the glory of vindication; and that Trash Artists are, and of Right ought to be unhindered in expression and      //
//    unslandered in character; and that they are Absolved from all falsehoods raised against them by their cynics; and that as     //
//    Free and Independent Creators, they have full Power to levy War, conclude Peace, contract collaboration, and establish        //
//    community and governance. And for the support of this Declaration, with a firm reliance on the protection of Trash            //
//    Dependence, we mutually pledge to each other our Lives, our Fortunes and our sacred Toters.                                   //
//                                                                                                                                  //
//                                                                                                                                  //
//                                                                                                                                  //
//                                                                                                                                  //
//                                ]@@@g                                                                                             //
//                               g@@@@P                         ,,gggNggg,                                                          //
//                             ,@@@@@P                     ,g@@@@@@@@@@@@@@                                                         //
//                            g@@@@@@w,,ggpgB@@@@@@@@@@@@@@@@@@@@@,  @@@@@        ,                                                 //
//                      ,,,gg@@@@@@@@@@@BRMP***""""@@@@@@@NP"""$@@@@@@@@`      ,@@@@@@                                              //
//                 ,,g@@@@@@@@@@@@@C            g@@@@@@P"     g@@@@@@@P`    g@@@@@@@@"                                              //
//             ,g@@@@@@@@@@@@@@@@@@          g@@@@@P"       g@@@@@@@P    ,g@@@@@@@@@                                                //
//         ,g@@@@N*' ]@@@@@@C ]@@@"       ,g@@@@P"       ,@@@@@@@@@-   g@@@@@B@@@@P                                                 //
//       g@@@@P"     @@@@@@-  @@@P      ,@@@@@P        g@@@@@@@@@"  ,g@@@@"  @@@@"                                                  //
//     g@@@@`       @@@@@@   ]@@@     g@@@@@C       ,g@@@@@@@@@*  g@@@@P"  g@@@@                                                    //
//    $@@@@        @@@@@P    @@@@    @@@@@C       g@@@@@@@@@@@,,@@@@@"    @@@@C                                                     //
//     %@@@Ng,,  ,@@@@@P     @@@     '*NBP     ,@@@@@@@@@@@@@@@@@@P`    ,@@@@                                                       //
//       "*PN@@@@@@@@@@Ngggg@@@@,           ,g@@@@"  ]@@@@@@@@@P^      g@@@P                                                        //
//             ]@@@@P***MMNB@@@@@@@@@@@@@@@@@@@@@     "%@@@N""        g@@@C                                                         //
//            ,@@@@`        @@@-     `]@@@@@NRNN@@@@@@g@@@g          @@@@                                                           //
//           g@@@P         -@@@     ,@@@@@*         `"**RB@@        @@@P                                                            //
//         ,@@@@*           @@@   g@@@@*-                          @@@P                                                             //
//        g@@@@             $@@@@@@@P-                           ,@@@P                                                              //
//      ,@@@@@              g@@@@N^                              @@@P                                                               //
//     ]@@@@P            ,g@@@@PP                               @@@@                                                                //
//       `"           ,g@@@@"-                                 ]@@@`                                                                //
//                    B@@N'                                    ]@@@                                                                 //
//                                                             $@@P                                                                 //
//                                                             "@@                                                                  //
//                                                              -*                                                                  //
//                                                                                                                                  //
//                                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TAR is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
