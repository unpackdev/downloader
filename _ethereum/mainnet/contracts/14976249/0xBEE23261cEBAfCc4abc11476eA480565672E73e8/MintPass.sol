// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./ERC1155Supply.sol";
import "./Address.sol";
import "./Ownable.sol";

// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// PPGGGGGGGGGGGGGGGGGGGGGPJ~^::..     ...:^^^...:^~:                   ... ..            ..::^~^::^^~!^:::~~~~!7?JJJYJ?YP5YYY?7!~~^^!777!..::^~7???!.             .^~!^..   ..:!J5PPPPGGGGGGP5GGGGGGGGGGGG //
// GGGGBBBBGGGGGGGGGGGGBBG55J?7!!~::::::^^^::.     ...  ........        ..........  .:.    ..:^^^::^^~~~^^~!77??J5Y!~^ .5GPGBP5YY?!!!7???:   ::.^?JY?7~..           .   .  ..:^~~~7YGGGGGGGGGGGGGGBBBBGBBBB //
// GGBBBBBBBBBBGGGGPPP5PGGG5P5YYJ?77!~~~~^^^^:...      .::^!77!!~~^^:....:::.::::::^^.      ..:^^^~~~!7?~^7?7J?7??^..:7P###BB#BBG5J??!!!!^.:!JYJ!?YYYJJ?7!~.               .:.::^^7YP5YPPPGBBGGGGBBBGGBBBGG //
// GBBBBBBBBBBBGGGP5YJ?77?J????JJJ???7!!!~^^^:^:..     .......:^~~!!!!!~^^^::^^:^!?5P?::.     :~!????JJJ?J?:....:^!7JG######BB#BBBGPPP55J?YG5JPPYJY555555?!.                   ...^^^!?YJ5GGGPPGBBGGGGG5JJP //
// GGGGBBBBBBBBGGPYYY5J!^^::.:.:~!!7??7~~~~^^::.      .:.    .::::^^~~!77!^.:::?Y5?7?J7?7:      .:::.:...^Y5YYY5PB###########B###BBBBBBBBB##GYBBGP5PGPJ!:....                      ..^..~5PPPP55GPPGGG5!75B //
// GGGGBBGPPPPPGGGPPPP5YJ~..:.  .:..:!!:..:^^:..    ....    .::^^^~~~~~~^:....~G#GY?YGGGPP57~~.        .^?P############B#########BB#B#B#####BPGPPPG5?~.  ^!7:                       .. :!JYJYPPPPPGGGPPPGBB //
// GGGBBGP5J^.JGBBBGGPP5YJ!.    .     ..  :!~^:.        ..:::::~!~~~!!!~::.  :5BBBBBBB#BB##BBB5!^^::^!JPB##BBBBBBB####BB########BB###########BGP55GGBG5Y7JJ7!~:                        ^~^!:^JY5PGP5?:JGGGP //
// GGGGGPP?: ^5GPGGGGGGPYJ7.   .     ..  .~!!~.    .!77?J?7!!7YPGGPJ!^:.   .~5BBBBBBBBBBBBBBBBBBBBGBBB#BBBBBBBBBBBBBBB#######BB#BBBB####BB##BBBB#BGBBBBGJ?7~7?!^.                      .^:. ..^!7YPP5YPGGPY //
// GGGPJ?^  ~GBGGPPGGGGGPY^  ..    ^~~~!7!!!~^.    :!JPPPGGGBBB##B#BPY?77!7PB#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB####################################BBG5YJJ5PYJ?!.                     . ....^^:^^7JJ7?P5YP //
// GP5J!. .!GBBBGGGPGPP5J~.  .. .~JJJ??JJ?77~..:..^!?PGGBBBB########B###############B####BBBBBBBBBBBBBBBBBBBBBBB#####################################B5YYJY555YJ??~:               .     ....:^:^^^^^~?P5PG //
// 57:::.^JGBBBBBGGG5?!??~:::...:!YGGPP5YJJ?7^:::~7YG################################BBBB#####BBBBBBBBBBBBBBBBBBBBB######B###########################PYPGPYY55Y5PP5Y?!^.         .:^..        ....:~YPGGPGB //
// J?J5GPGBBBGGG5??J?7~^!JYYY?!~^~!YPB#BBBG57^^~5BB###################################BBGGP5YJ?!~!7??JY55PPGGBBBBBBBBB###B###########################BGBGBGYY5PPPPPPPYJ7~^:::::^~~~!7!^.       .!?YPPPPP5PG //
// BBBBBBBBBBBBBP7~!~^:::^?GGP5Y7!~~7PBB##B#BBB###################################BG5?7!^:..  ....     ...::^~!?Y5PGB#B#################################PPGGPY?J5PGPP5JJJYYJ7~^:~7JYJJ?:    .  :YPGP55Y5GPP //
// JB#BBBBBBBBBBBP5PPY?!::?GGPGP5J~^~~75#BBB###########################BB#####BG57^. .!^.        ...             ..^~?5GB################################GPP5GP5JJ5PP555YJ?????7~J5YJJ~.    ..  .~?JJ!^?GG5 //
// GBBBBBBBBBBBBBGPP5J55J5GGGGPGGP?!7^^!P##################################BY!~:           ::::. .   .                 .~?PB###############################GY5GPG5YJJ?77??YG##P7!7JJY?^.    ...    ..  :?PP
// BBBBBBBBGGGPYJ??JYPGBBBBBBPBBBG55J7!!!5###########B#######BB#########BGJ^        .    :!J?!~^^^^. ..   .        ..  .  .^?PB################################GG##BBGGPGB###57!?YYJY57:. ....   .~7:  ^J5G
// BBBBBBGP5P5YY5PY~~7YGBBBBBGBBBBBBBP?!~J#################B##########GJ~.      .. .     ^~~^::.:^^. .. .     .    ......:7!..^?P##B############################BB##BBB#####GY?JY555PP7:.        .:!!  :!Y5
// BBBBBGGGBGGGGBGP?^  7BBBBBBBBBBGGP5?!^Y######################B###P7.  . .:.          .     .... .   ..     .        .::^:..  .!5B####################################B#BGJ7?55PGPGG?:.               ^JY
// BBBBBB##BBBBBBG5Y?^ :5BBGBBBBBG5J5Y?!!5############GPGGPGPPB###P!. ...^^......    .:::.    ..              .....   . .::.       ^YB##################################BB#P?!!?5PGGGG5J?~               7Y
// GPGBB##BBBBBBGGGPJ?^.~G#B####BG5Y5Y??5B##########B55GGP5J5YYPG?.  .::?G5^.::^:^^:.::... .               ....:^^:..  ...^:.   .    ^5##################################BBPJJ!7PGGGGGGBG5J?~... :::^^.  !Y
// JYGG5PGBBBBBBG5J?7!::J#######BGGG5JYP###########B5BBPGGPGYP77JJY!^:::^!^:::::::^::......................::.....................~!~:.7B#################################BP5Y?J5PGGGGBGPGBG5?:.^!~:^??^ :7
// JPGGY555PGBGG5YJ?!~~?G#######B5JPGPB###########BPBBG55PGGY5JJ55GJJJJ7!^:^:^~~^^!~:^^^^:::^::::::::::::::::::::::::::~~::::::::!JJJ7^:~P################################BP55JJY5PPGBBBBBBGG?:^!!~!?5GPY!^
// BBBBGPJ5GGGGPPGJ~?JG#########B5JJG#############PBBBPGGJGG?G?5GGB5Y?7?J5J?!~~~!!~^~~^::^^^^:^^^^:::^^^^^^~~~~~^~^^:::!~:::^~~~~7!^^^::.:Y################################G7^~!7?55YJ7YJYGGJ^^!7!?YPGPPGBG
// BB#BGBBBGPBBBB5JP#############BPJP############GGBBGGGP5B5JGJGBB###BBGPG5Y555JJ?!~^^^^^^^^^^^^^^^^^~~~^^~~~~~~^^^^^::^^^^:::^^:^:::::::::5#################B##############BJ^:.:^:..:~:.75!^~?Y?JBBGPY5GG
// B##BB##BBBBB#BB################B5Y############YGBG5BGPBGJ55GBBB#######BBGP55PGGP5?!~~~^^^^^^^^^^^^^^^^^^^^^^^~~~^^^^^~!~^^~~~^:::::::::::P################B################B5?~^^~???7..~~^!?Y?~?PGPPPPG
// P############################BGPPP##########&PYBBG55PBPYP5PGB############BBBBBP55PGJ~!!~^^^^^^^^^^^^^^^^^^~!777!^^^^^^^^^^!!~^^:^^!JYJ7^:~B####################################BBB#BP7..^Y!^~!7?J?5GGBBG
// P########GJ5###############BGPPY5B##########&YPBBBBGBPYBGBBGB#################BB5Y557?YP5!^^^!~^^~~^~~~7?5PGPGGPJ!~~^^^^^~~^^:^!Y555JJY7::J######################################B##B~..:?5?!~~~7???JJ?J
// B########BJ7P#############BPYJYYP############GB#BBBGPPBGB######################BPGG55?7JJ~~7?7!!~~~!7~?5GG5?!!!777~^^^^^^^^:::^5P7!P57^!!:^B####################################BBBB#5:..:75P57~777Y555P
// #########B5!J#######BP5YGGP5??PB###############BBGPPBBGB####################BPPB#BBG55PJ?7!??JJ?7!!?5PBGP5J?7777!^^^^^::^::::::?57~!!7^^~::JB##################################BBGG###5^   ~J7~!5BGGPY?J
// B#######G?~~5#B#####PYYPGGP55G#################BBGBBB##&####################G?YP#BB#GY?7?YJ!!??!~!7JBBPYJ?777!!!7!!::^::::::...:~!~^:.....:~B####################################BGGGB#G?^.     .^7555??
// ######G7^^7PBGG##BP?!GBP5YYP######################B5Y5PGG###########################BY!!~^~~^^::^^^?PP55PPPGBBG5J?~:::^~^~~~^::....... ::^^~#################################GB###BGPPG##BPJ?7^~: :G#BBB
// ######P^~P##BGGBPPGY5B##BB########################&J:^^!Y##BBBB##################GYJ?7!~^^^:::::::^:7JPGPP5PGBBBG57~^:^~75P5Y!:..... ...~~:~B###########################B###GG#######BB#######JP5!!5BBBB
// ##BBBB57G#####B?~5#################################J^!5PB##GB#BGBBGG############P~!!!!~^:^^:::::::^::~~!?YPBBGPY??!:^:~^!?~^~~~?7:....:^~^:7B##################################GPPPB#########P~JBB~.?BBB
// BPJJJYPB######5~J##################################?:7G###55GBGBPJ55B###########P!~^^^^^::::^:::::^^^:^^^~!7?77!~^^:^::^~:.:::~7J!!??7JJ!^~?B#################################B5YYP##########B?~5GY5PPBB
// BGPGBB####BBBGJYG##################################J^^5##G??GG5?77PPB###B5GBB5YY777??777??^:::::^^^^~^~~^:.:::::::::^:..^^^^::^:!J?YY7~^^^~J###################################GGGPB#####BGPPJ~?BG5PG5GG
// ########GJ?YP5J7JB#################################P~~?5G5?77?!!7?5PB#BGP5GBGY7???J?77?7!?~^^^~~~^~?7::~7~^::::::::....:^^~^:.:^J5555YY!:^^5##################################BB#BBG#B55J?YPPY!Y#G5PP5GB
// ######BBG??PGPPPG###################################!^^~!~!~^~7?JJ5P5577?Y55PPY?!~~!~~^^!!~J57!7J5PBBPJJY5J~:^^^^::::^^^^^:^::^!5?7~^~~~^~?B######################################BBG~.!75PGGGPG#5!7755P
// B###################################################?^!~^!777?PG#55J!7!?7J5PPY?7!!?!~~!7~^7YJ7J5YP5Y55Y7!?5PJ~~~~^^^^^::^::::^~7YJ7^^^^:!7P######################################BB#7 :7!J5PGGGP7^:::::7
// ##########P5GPPBB###################################B~~~?JJPBGPJJJJ7?Y?77YYY7!77!77?J7!!^^^^^~77!!~^~!~^~^^?P57~~^:^~~~!~~~~::^^^!!~^^^!7Y##########################################J  ^?77PPPY: ..^~?Y5
// ####BBB###GYJ?JY?7YB#################################5^:::!PBPJJPJJJJ?7!!JY7!~~!!!!J!!~^^^^^~!!!~~!!77~~^^~^~7J?!:^^^^^~^^^^~~~^:.:^^^!7?B##########################################B7. .^7PP5^...!7J5?7
// BBBBBB##GP5YYJ5PP?Y###################################?^!!~7JJY55J7~~7!!7?77~^:^^~7^^^:::~^?BBBBGGBBBBBGG5?!^^~!^.^:...^!~^^!?~^::77!!??P############################################GY7^ .^7!.. ^PP?!75
// GBBBBBBBBG5JJJJP#BGB##################################B7:^.::^^^^^~^^~~^^^^^:^^^^~^:^^^~JG7?BPGGPP55PPGGBBBGGYJ7:......:^:::^^^^~!7~^7!?#########################################BP7~::PB7   .. .~YP!7YP
// GGGGGGGBBBGGPP5YP##P5G#################################B?~~~~!7~^~?J7~:^^^::::^~~~:7Y5G55Y?YPJ?JY5PPGGGGGGGBP!^^:.....:!^::~!~^:::::~~7B#######################################BB57~?J7J?.      .^?J?7YP
// BBBBBB#####BBBBPY5G?:!5GB################################P5PPP5JP57??J~::^~~:::^^^^^~7J??J?YPPP5PGGGGBBBB5JJJ!^::::.:^:.::~?7!:.:^~!7Y#########################################BB?:^:. ~~      ..^?5P55P
// GGBBBBBBBBBGPPGGPY5P7^^?B#################################P7~!!7?77?J557^:^:~!~^::^^~7!!!7YYJYJJY55GGPPPY7!7?~^^::.:~!~~~^~~^::!Y5YJP#########################################Y~!.  :^.7^      ~Y5PPGBGG
// GGGGBBBBBGGGGPPGG5J7!!!5B##################################G?!^~^^^7~~!J5?^:^^..:^:^!!7?!~~~~^^^^~~~~~!!^^^^.......!JYJ??J~.:^JY?YP###########################################Y .  :PGJY!     .^JGGGGGBB
// PGGGGGGBBBBGGPPPGPPY!75B#####################################P!:.::.^^^^7~:. .:^:...:.:::^~!!~~~?7~~::::... ....: 7?^^^7?!^^~??JPB############################################BJ7: ~BBPPP^     .?GGGGBBB
// PGBGGGGPPPPPGGGGGBBGGGBBBGPB##################################BY!:.....::...:..::~~:::^^:~?!~!7Y555YJ?~:.:^::.:.  ~!~!!7~::!JPP################################################B?^ .5GJ5G5: .  ~BBBBBBBB
// :~7?YYJ7J55PPP5Y555P5555Y?!?PB###################################G?^:...::..^~^^::!!~~~~!?7:^77JY?7!^^~!7^~~^^.:7Y7~!!7!^!?YG############################################BBBBB##G~  :JPPPG! ..:JGBBGBBBG
//     ...~JY5PPPPPPP5Y??J?7J5^.^!YB##################################B57^.:~^^!~^7^^:.:..^:!?7!:. .:..:~^:.....^:JPP555YY7JBB###################################B#######BP55PPPPGBB~   :555G~  :?J5GBBBP?!
//       ..^~!?JYYY??JJYJ??!~~~..^.^P#BBBBBBBBB##########################GY!:..~JJJJPY7!~~~~:  ..::~^^...^^..: :!JPPG5J5P5B#################################B##BB###B##P7:... . :JGGJ.  .?5PJ  .~!5GGGGP7:.
//   .       ...:?JJYYJJ?77!!~^..:!^~5B#BB#BB#########B#####################BPJ!!~^!~~~~~^^:^!. ~!~~^^~7JJ7!7JYPBBBBPPB##############################################B?:    :7Y?75GBY  ^JY?7^  .?!J5PP?: .:
//  ...          ^JYJJ?777~^~!~:..75!~JB###########B##GB########################BGPY?!!~!?YJ?7~?5YYJ?J5Y5G5PGBBB#B###################################################J      .???GPGP: !5YJ??J!. :. .!G! . .
//               .~7!77!!!~~77!^:^5BY!JB##################################################BGGGGBGGP55PGGB############################################################7    ....:JGGBP^?JJYYJ555!.   .7J^~!!?
//                .~^^!!!~!!77~:::!5BBB##############################################################################################################################P!.   .  Y#BBBB5YYP5YJ?!~::.  .. ^~!?Y
// ..             .~~:^~^~!7?J7!~^~?P###B#############################################################################################################################5     . ~BBBP5555?~..        ::~!~!??
//  .             .7???77!???JJY55555PBBPG########################################################################BB#################################################BB7    ...YBGY??7:   ..  :^:~J5Y?!?5P5
// ..             :^^~~7~.^7?JJYPGPJ?7JGGG##########################################################################################################################BG##?.   . !GJ??7^      .~JP5PGGGPPGGPP
// ^                  ..::^7?77Y5Y?!!!JB###############################BG##########################################################################################BB##BB57!^  7P?!!~^   ..^7YGGGPPGGPBBBGP
// ^                    .^7!^::!?7~^^JBBB###############################BBB##############################################################################GG########GG##B5BBP~  7G57~^^  ^?!~^^!7?JPPPGGGGGG
// :                     ...   .....!GBGB###################################BB#############################################################B###########BBBBBBBGGPGBG#GJ~:^^^^. 7PJ~^^~^:::       ^J5GGGPPPP
//                                 .JBBBBBB##BBB###########################B################B#########################B###############################BBBBBBBBBBPGBP?:   .?5~:JP7!~^~!~.    .:~~^^?PPGPPP55
// .                          .:.  .JBBBBBB###BB############################################B############################################################B#####BB#Y.     ?BY~YBP?7!~^.     .7JJJJ??55P5555Y
// .                           ~Y7:^YBBBBB####################################################################################################################GYJ5:     :GBGPPP5JJ7~^.    .^!!~^^~~J??Y555P
//                              !PYJPBBBB##GPGBGBB###5YGG##################################################################################################BGGBGPP?.   .J5JJ??777~~77:    .:. .:.^!????JGGG
//                              .?PGBBBB###BGGG5Y5GPPGB5~?B#########################################################################################B#####BG5GBBBBB^  :^~^....::^.^?J!    .:::^??~?55555GGG
//                      ..       ^??JPB##B57~~~~^::::^5BJ7PBB###################################################################################B###B####BG5JG#BGY?~  .:^....::^^:!!^:    .!Y?7??JPGGPGGGGG
//                   . ..       ^7!~?PBBB7....::......:!~::^^!7JG#B5G####################################################################BBB####BBBB####BGPYYBP!.     ......::.....        :?555YPGGPPPPGGG
//  ..               ..^!.      ^YYJY55PGJ!^::::~~~^:^:...   ...^5BY~JB####################################################BBBB#######B#BBBBBBB##BBBBBBBBBBBB!. .^:::^^......               ^JJ55GGPGGPGGGG
//                    ..^:       ^!!~!JPGGY?7~~7??7!!~^:..      .!BB?^P#BGPGBB######################################BB########BBBBB##BBBBBBBBG5JJ?7?J5GGGGGG!  .JYJ!^^:.                   .:^^~YGGGGGGGGGG
//                        .         ..^7J7~~^~!7777!?!^^^:.     .^!?J!J5J7?YJPB###########################B#####BBBBBBBBBBBBGGGGBBBBBBBBBBBGJ~.     .:~!7!7?.  .!!!^..                     ..:^!5GGGGGGGGGG
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/**
 * @title Token contract for the Nifty Mint Pass
 * @author maikir
 * @author lightninglu10
 *
 */
contract MintPass is ERC1155Supply, Ownable {
  event PermanentURI(string _value, uint256 indexed _id);
  string public constant name = "I'm New Here Mint Pass";
  string public constant symbol = "INHMP";

  using Address for address;
  uint256 public totalTokens = 0;
  mapping(uint256 => string) private tokenURIS;
  mapping(uint256 => uint256) private tokenPrices;
  mapping(uint256 => bool) private tokenIsFrozen;
  mapping(address => bool) private admins;

  // Sale toggle
  bool public isSaleActive = false;

  event Donation(address indexed _sender, uint256 _value);

  constructor(uint256[] memory _tokenPrices, string[] memory _tokenURIs)
    ERC1155("")
  {
    require(
      _tokenPrices.length == _tokenURIs.length,
      "Token prices array size and token uris array size do not match"
    );

    for (uint256 i = 0; i < _tokenURIs.length; i++) {
      addToken(_tokenURIs[i], _tokenPrices[i]);
    }
  }

  modifier onlyAdmin() {
    require(owner() == msg.sender || admins[msg.sender], "No Access");
    _;
  }

  /**
   * @dev Allows to enable minting of sale and create sale period.
   */
  function flipSaleState() external onlyAdmin {
    isSaleActive = !isSaleActive;
  }

  function mintBatch(
    address to,
    uint256[] calldata ids,
    uint256[] calldata amount
  ) external onlyAdmin {
    _mintBatch(to, ids, amount, "");
  }

  function setAdmin(address _addr, bool _status) external onlyOwner {
    admins[_addr] = _status;
  }

  function addToken(string memory _uri, uint256 _ethPrice) public onlyAdmin {
    totalTokens += 1;
    tokenURIS[totalTokens] = _uri;
    tokenPrices[totalTokens] = _ethPrice;
    tokenIsFrozen[totalTokens] = false;
  }

  function updateTokenData(uint256 id, string memory _uri)
    external
    onlyAdmin
    tokenExists(id)
  {
    require(tokenIsFrozen[id] == false, "This can no longer be updated");
    tokenURIS[id] = _uri;
  }

  function freezeTokenData(uint256 id) external onlyAdmin tokenExists(id) {
    tokenIsFrozen[id] = true;
    emit PermanentURI(tokenURIS[id], id);
  }

  function mintTo(
    address account,
    uint256 id,
    uint256 qty
  ) external payable tokenExists(id) {
    require(isSaleActive, "Sale is not active");

    require(
      msg.value >= (tokenPrices[id] * qty),
      "Ether value sent is incorrect"
    );

    _mint(account, id, qty, "");
  }

  function mintToMany(
    address[] calldata to,
    uint256 id,
    uint256 qty
  ) external payable tokenExists(id) {
    require(isSaleActive, "Sale is not active");

    require(
      msg.value >= (tokenPrices[id] * qty * to.length),
      "Ether value sent is incorrect"
    );

    for (uint256 i = 0; i < to.length; i++) {
      _mint(to[i], id, qty, "");
    }
  }

  function donateFunds() external payable {
    require(isSaleActive, "Sale is not active");

    emit Donation(msg.sender, msg.value);
  }

  function uri(uint256 id)
    public
    view
    virtual
    override
    tokenExists(id)
    returns (string memory)
  {
    return tokenURIS[id];
  }

  function tokenURI(uint256 tokenId) external view returns (string memory) {
    return uri(tokenId);
  }

  function withdraw() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  modifier tokenExists(uint256 id) {
    require(id > 0 && id <= totalTokens, "Token Unexists");
    _;
  }
}
