
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Aliens Learn Ukranian
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                `````````````````.....''''''''''''',,,,,,,    //
//                                                                                                                    ````````````````......''''''''''''',,,    //
//                                                                                                                       ```````````````..........''''''''',    //
//                                                                                                                           ````````````````......'''''''''    //
//                                                                                                                            ` ````````````````......''''''    //
//                                                                                                                                   `````````````........''    //
//                                                                                                                                    `````````````````.....    //
//                                                                                                                                       ````````````````...    //
//                                                                                                                                         `` `````````````.    //
//                                                                                                                                             `````````````    //
//                                                                                                                                                 `````````    //
//                                                                                                                                                    ``````    //
//                                                                                                                                                       ```    //
//                                                                                                                                                              //
//                                                                          `',,~+;,'.                                                                          //
//                                                                    `'~^vyXbbKqUAbdbEc;.                                                                      //
//                                                               `'~+7akkUq6XXPmSmwhAKR%Rbj!`                                                                   //
//                                                            `_<Jymm5}xtJJtJJJJJJJtYuyw6bDDq?'                                                                 //
//                                                         `,<fafIcL|Li\7JtIYYnYYssstJzzzzzsyXUi`                                                               //
//                                                        'Ljomf\>>|\7ztn}fjjJxjj}}}{YsJz7v\iiiJ=`                                                              //
//                                                      '=zommj7|>*izx}jyojz||yyyyjjj}{YsJzz7\i|<;                                                              //
//                                                    `;f}Smm5}zc||LL|{aSj*<<?yZaoyyyfs7JYxJJz7\L<;                                                             //
//                                                   `=yoShEmojfsc|*<<*c5a?<<<|j5yyfv|*\{uIsxJzviL*;`                                                           //
//                                                   !fZPUhPSaofuzc|<<<*}E}*<<*ISSaT<<?t{{nYsz7\iiL*;                                                           //
//                                                  ,7oXkwkEmSajYzqb6L{bRRDa*JhA6Uh\7sjfjjjf{J7\LLL|<`                                                          //
//                                                  =JSkXkEmaoI|*S8W%UhmhUKqmW#Q&Wbb6PSjjyyyjfnzi|||*,                                                          //
//                                                 `|yAqowmjT?<<***<<<<<<****?|L\Jjaoj}ItJT7aoj{J7i||!`                                                         //
//                                                 'imXa?\*Ji<<<<<<<<<<<<<<<<<<<<<<<<<<<<<y8&N8%DKqkmu;`                                                        //
//                                                 'zwkL<<*z*<*\7jkX6P6bE\<<<*oZy}xL<<<<<jQQQQQNW6af7*~^*i!.                                                    //
//                                                 _}yni<<<<<<*?ijqd#QQQRj*<LKQQQQQz<<<*JEQQQQQB8RqofL   'KgS,                                                  //
//                                              `<jyowRdoY\?*<<<<<<<LtaD#BKnNQQQQDi<<<*SqmybQQQQQ#%Uoz .=wD%;                                                   //
//                                              *EPX66bbEES\>*?||*<<<<<*7a%RN888h*<<<?PbUmjuNQQQQQQQq5oK\,j<                                                    //
//                                             `jExwkmKb5jY?+=|7nszc|*<<<<*nKggWo*<<ik6kXkZf}RWNNWDqKJ;` ,q                                                     //
//                                             'oIoh6RKh}z7<+^*Li7}aPEy7*<<<iNQQQz*vXX6KqqEytuq666Efi    a:                                                     //
//                                             `sIUqqdEwX{jz|=**itSqdD%gqI*<|&QQQiuRN&#N##%qwYWgbky\*` `7_                                                      //
//                                              !7wUXq6qKawji??|7aqDR%gW8NZ*EQQQgoQQQQQQQQBQBqK8NN%Xj+;;`                                                       //
//                                               ;{S}ZAdqKkjJi|7jAD%gW8#QQQjBB##WQQQQQQQQB&QNKR8DqPf\,                                                          //
//                                                ;xI6bD%%q}uxzfEDggWN#QQQQNBNWW8N#QQQQQQgDdXhA8NDkyz,                                                          //
//                                                 `~z6bRgdyIy5PK%NNNN&QQQQQQB###&BQBN8WWDqP5akgQWqo7`                                                          //
//                                                    `\S6Ez}wKbD8&BN8#QQQQQQQQQQQQQQQQQBNgDXSXDQgAy;                                                           //
//                                                     `7o5vukDgW&QQ&N8QQQQQQQQ#B%gNWg8RDRWQQ8gN#bXc`                                                           //
//                                                      'Ij7jXbg8BQQQ#N#&BQQQQ@QQQQQQQQN%K6%QQQ&dUj'                                                            //
//                                                       ;}JyUb%N&QQBNNN888NNN&QQQQQQQQQ@@Qgq%#Dkj'                                                             //
//                                                        =soqgg#QQQQB#BN8g%%%gWN##WWWWgNgkyS%Rkm_                                                              //
//                                                        `z}X%8NQQQQQQQBNg%%%ggN&BB&#NgRKoukDkX^                                                               //
//                                                         ~j6bDWB##QQQBNW%%ggW8##BB#N8RKSfjKq6=                                                                //
//                                                          zUD%%WN#QQQBNgRDR%ggWW8Wg%DKXZyyAUz                                                                 //
//                                                          ~wRN#NNNQQQQ&NgRDdbKKKKKqAXm5jjoqz`                                                                 //
//                        `.':~~,'`  ``                      7bNB#WNQQQQQQB&#8%RDdbDRDAwyySwz`                                                                  //
//    ,,,'''`         `,+7ymk6A6hajJ|L7Jv=,`    `'__,'``     :mgBQ&gkDBQQQQQQQQQ&NN#&NgDbKAy`                                                                   //
//    ;;;;;;^,      '+}XDR%%%%88gRDDbdR%Rqm}=~;Jk6qDKqXXmu=.  cD#B&DZZKgQQQQQQQQQQQQQQB&gWXv                                                                    //
//    !!!!!!^;`   ~7hbgBQQQQQQQ&Ng%%WNNN#QQ8A5}IuywUR%%8ggDa~ ,68#NRZoAK%BQQQQQQQQQQQQQBgUy7.                                                                   //
//    !!!^^^=!, .LXqDQQQ#gRdAXEmSwkKgBQQQQQQQgUSxsyhb8QQBBNgy,`nDN#gXaXqgBQQQQQQQB##NN%qXwyJ;`                                                                  //
//    !!!^^^=!~;jgb%QQ%kyjjjjyyyyoZEUbgBQQQQQQQDkfyERQ8gggg8%m';hg#NqmqR#QQQQQQQ#gg8NWDK6P5fiL!'                                   `~?v                         //
//    =<<+^^<^7UQNNQ&Xj}jy5SSSmwwEEEkXUdgQQQQQQQ%KEUg6XfL^;~;;;;tDN&RkqDBQQQQQQB8g8NW%DK6Paysfyy}||^~~;;~_'             `.         'ivz.                        //
//    L|=^^^^JqQQ8QQAyyawhXU666UUUUXUUXUK%QQQQQQQ%bkk6WBQQ#RK6khj6NQNqARQQQQQQQ&NNN8gRDqUPmaoSEhjjyjfnfkbgNRUS}\*^;,..'^>v    .~*yKWNWRX7!.        `,,          //
//    ==>==={b#QQQQ#hmwPkXU6Aqqqq66UUXXXXq%QQQQQQQD%UkUKQQQQQQDS#yWQB%KgQQQQQQQBB&NW%DbAUXXkkXEyoSwEkRQQQQQQQQQQQDs*|LL|<^,`.v8QQQQQQQQQQQWw;    `yQQQQD#Wf~    //
//    kz<*<zd8QQQQQ#XPPPPPXXXUU6UUUUXkPEEXKgQQQQQQQRgd%Q@@@Q!,'5QjRNBNR8QQQQQQQQQB#8%DqA6qKbUZoawhDQ@@@@@@@QQQQD5sf}}}unY7\L|<<ifqQ@QQQQQ@@QQD|:`'DQQQQQQQQQ    //
//    kDz*iqNQ@QQQ@QUmwkUqKKbbKqqKKKqqA6XXUdNQQ@@QQWg&gQ@QW6n5tqUI6g#BN#QQQQQQQQQ&#8gDKbdDdUhwmh%Q@@@@@@@@@@@BZyyfjjjjffjyyyfs7L|<*j%Q@@@@@@@@QQQQSsd%QQQQ@@    //
//    qBXiXRQQ@QQ@@QD8QQQQQQQWRDDDR8QQQQQQQQQQ@@@@@Q8QBkRbwN#Qqz=|jKNBQQBQQQQQQQB#N8g%R%Db6UXUgQ@@@@@@@@@@@Qqy5aaaZZZaoyjjjffyay}ziL*iS8@@@@@@@QDW|kQgqUAgQ@    //
//    DDyED8QQ@QQ@@QQQQQQQQQQQNgDD%&QQQQQQQQQQ@@Q@@@QQ@PSQ#oz?^;<LvEW#BQBQQQQB##&#NNN8RdKqqq#@@@@@@@@@@@@@QUXXXkkhEEPEEmSZayyjjjyayfz\i|LhQ@@@@@8mmWf<|7}omk    //
//    5zsXDQ@@@Q@@@QQ@QQQQQQQQQDqXRQQQQQQQQQ@@@@Q@@@QDwz*|||LiLi*zTy%8N&BQQQ&N#BBBNgDbbKqKB@@@@@@@@@@@@@@NqKqA66UXXkXXXXkkPwSayyjjjyao}zvi|}%@@@@%yi\y6gWRXm    //
//    ^jSgQ@@@Q@@@QQQQ@@@@@QQQ8EwhD#Q@@@@@@@QQ@@QNdoJ\iLLLi\7zz?>{7Id88&QQQBNNN8RDbddKAqR@@@@@@@@@@@@@@@%KqqqqqqqqAqAqAq66UXkEwmayyyyjyoy{zvL7XQ@Rv\S@@@@@@Q    //
//    zZ#Q@@@@@@@Q&#N8#QQQQ#8gbEEEqD%NQQQQQBQQQ6YstJJI{jyj{tz\***LxokW8BQQN%RbKKDdKKUXKQ@@@@@@@@@@@@@@#q6U666AqqqqqKKqqqqqqq6UXkPmZa5yyyyoZynzcLS%7!\QQ@@#SB    //
//    m#QQ@@@@@QQ#N8g%%gg%%ggRXahw6DRR%gN#&QWw{YY}yof7}5yz|**>=**??zaqbdKqKddKKKKq6XAN@@@@@@@@@@@@@@@dXXkkkXXU6AqqKKKqqKKKqqqA6UXkEwSZooyyyyS5Yz7ii|zw%8%ggQ    //
//    NQ@@@@@8aYuuj5EDgg%%R%WgoEA6XgQNWWN&QbfyoShkajzJyo}|*<=>**??LzSqKq6AUUXXkk66AD@@@@@@@@@@@@@@@NXEwEEEPkkXU6AqqqqKqqKKKKqq666UXXhEwmZoyyy5Sa{J7i7K&#QQQQ    //
//    @@@@@@Q7wwSSZajz7xaKDR8NNNNN&QQQ8N&ga5wwmEwajYvsyyz|***|i|*<|ix5S5ayawwPX66KB@@@@@@@@@@@@@@QqEwmwwmwEPkXU66AqqKKKqqKKqqqA66U66UUkkEwZao5oaES}Jz\Z#QQQQ    //
//    @@@@@@@QB8%DbqXEZy}J{U%8QQQQQQQNN#NjjomwEEaj}z\nyfv||*L7zL|LiTtjowwEkwmPXAR@@@@@@@@@@@@@@@gEmmmmmSmmwEhkXU66AqqqqqqKKKqqA666Aqq666UXPwSSZoSSwauzT7DQQQ    //
//    @@@@@@@@@@@@Q8%bUhEmoutjqKgWW###BQSfamwPEaj}IvinfI\||?7nxiLLizyZSwwEwomXqB@@@@@@@@@@@@@@QASZSmmSSSSSmEhhXU66qqqKqqqKqqqq6U6UU6qqKKqqAXEmSaSmZZwo{z\zw8    //
//    @@@@@@@@@@@@@QQWRdqXhEmjxuK&BQQQQRsySEkhwyfuziiJsz\L||z{Yi||Lzjj}yZ5yShR@@@@@@@@@@@@@@@Dwoy5oaZaZSSSwEhkUUUUAqqqAqqKqqqqA6UUUUqqKbbdbKUPmamwmaSZZ5}}J7    //
//    @@@@@@@@@@@@@@QQRbRDqEZaaoy8QQQQ@a}amEXhSjuYzii7z7vi||t}n|*iizfnt}5yyk#@@@@@@@@@@@@@@Qha5yyoaaaaSSSSwEkXU6UU6qqAAqqqqqqqqAUUXkXqqKbbddK6hSmmmSSmZoyjIT    //
//    @@@@@@@@@@@@@@@6<7hqmyyojjyu6DKKX|vt}jyyjnJJz\iv77zi|L{yt**c\7nItu5yq@@@@@@@@@@@@@@@q5yyyyyoaaoZZZmmwkXU66666qq66qqqqqqqq66UXkk6qKbbdDdqXwmwEmSwwwmSay    //
//    @@@@@@@@@@@@@j~_;*7zc7z=+<*|iL\T|<<<<>=+^;;;;!!^^+++^?nj7*?\\TJtYjm&@@@@@@@@@@@@@@8Z5yy5yy5aaooaaZmmEkX66qqU6qqAAqAqKqqqqqA6XhPXqbdddDDdqXPPEwmwSkXkkP    //
//    @@@@@@@@@@@@%v!=so5js7cii\cL||*=+^^!!!!;;;;!+==++=^;,,;*7*|TvJJujU@@@@@@@@@@@@@@Qkj5aoaoyyyoao5aZmEwhXUqqqqU66A666qbqqKqqAq6UkwEUqbbKdDDK6XXhPkwkwmEkX    //
//    @@@@@@@@@@@NE^LjAdKUwSmwEhPkX6a}zYywwm5yyyy}IxtJJxJ7LLzj7LLznfuyD@@@@@@@@@@@@@@8yjyZmaaoyyoaao5aSmwEXXXqKbq6UqAUXUqqqqqqqqqUUXEwkAbddDDDDKUXhkPhXPoaEh    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ALU is ERC721Creator {
    constructor() ERC721Creator("Aliens Learn Ukranian", "ALU") {}
}
