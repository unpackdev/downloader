// SPDX-License-Identifier: MIT
/******
__        __    _ _   ____  _                 _     ____        _ _      __  __  ____  _         _             ____
\ \      / /_ _| | | / ___|| |_ _ __ ___  ___| |_  | __ ) _   _| | |___  \ \/ / / ___|| |_ _   _| | ___  ___  |  _ \
 \ \ /\ / / _` | | | \___ \| __| '__/ _ \/ _ \ __| |  _ \| | | | | / __|  \  /  \___ \| __| | | | |/ _ \/ __| | |_) |
  \ V  V / (_| | | |  ___) | |_| | |  __/  __/ |_  | |_) | |_| | | \__ \  /  \   ___) | |_| |_| | |  __/\__ \ |  __/
   \_/\_/ \__,_|_|_| |____/ \__|_|  \___|\___|\__| |____/ \__,_|_|_|___/ /_/\_\ |____/ \__|\__, |_|\___||___/ |_|
                                                                                           |___/

BJ:~#&&&@G~^J&@&G~~!~7B@@@@@5^!PGGGGBBBBBB######&&&&&&&&&&&&&&&&&@@@@@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&##################
GJ:~#&&&&7^~!!7!~7PB5!~Y@@@@@5~!PGGGGBBBB###BBGG5YJ?777777!!!!77?JY5PB#&&@@@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
GP~:Y&&&&B!~JGGGBBBBBG7^J@@@@@P^!PGGBBBBP5J7!~~~!7?JY5PPGGGGGPP5YJ?7!~~~7YG#&&@@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
PBY:^G&&&@&?^?B&###BBBP!^B@@@@@Y^7GBGY7!~^!?YG#&&@@@@@@@@@@@@@@@@@@@&&#G5?!~!75B&@@@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
PGBJ:~B&&&@&5^!G##GJ7!!~~?B@@@@&7~??~^~?P#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&GY!~~?G&@@@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
PGGBY^^G&&&@@G!~7J!^5&&&BJ^?#@@#7~^~JB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#P7~~JB&@@@@@@@@@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
5PGB#P^^5&@&@@&BGJ~~&@@@@@B!~YJ~^!P&@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&@@@@@@@@@@@@@@@@#5!^!P&@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&&&&&&&
5PGGB#G!:7B&@@@@@&!^B@@@@@@G~^^!P&@@@@@@@@@@@@@@@@@&#GP5YJ???????JYPG#&@@@@@@@@@@@@@&G7^!5&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&
5PPGBB##5!^7P&@@@@B~!B@@@&J~~!P@@@@@@@@@@@@@@@@@&B5?77777?JJJJJJ??7777?5G&@@@@@@@@@@@@@B7^~5&@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&
Y5PGBB##&&GJ~~JPB##P~^Y&B!^~Y&@@@@@@@@@@@@@@@@&GJ7777J5G#&&@@@@@&&#G5?777?P&@@@@@@@@@@@@@G!^!G@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&
Y5PGGBB##&&&#GY?777777~!~~!B@@@@@@@@@@@@@@@@@BJ777?P#&@@@@@@@@@@@@@@@&BY777?B@@@@@@@@@@@@@&Y~^J&@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&
JY5PGBB##&&&&&&&&&&&@#!~~?&@@@@@@@@@@@@@@@@&P?77?P&@@@@&#&@@@@@@@@@@@@@@G?77?B@@@@@@@@@@@@@@G~^?&@@@@@@@@@@@@@@&&&&&&&&&&&&&&&&&&&
?Y5PGGB###&&&&&&&&&@B!~~5@@@@@@@@@@@@@@@@@&5777J#@@@&BY???5&@@@@@@@@@@@@@G7?7?#@@@@@@@@@@@@@@#!^?&@@@@@@&&BG5J?777!77777!77?Y5B#&#
?JY5PGBB##&&&&&&&&@P~~~G@@@@@@@@@@@@@@@@@@57?7J#@@@&57J#Y!?#@@@@&#GY5G&@@@57?7Y&@@@@@@@@@@@@@@#~^?&@@&GJ!!7?YPB##&&&&&&&&#BP5J!!7~
7?J5PGGBB##&&&&&&@Y^~~B@@@@@@@@@@@@@@@@@@G7?7?#@@@#Y7?&&?7J#@@@#5?75??P&@@#?77?#@@@@@@@@@@@@@@@G~^J#J~!YB&@@@@@@@@@@@@@@@@@@&P!~?B
!7JY5PGBB##&&&&&@P^~~B@@@@@@@@@@@@@@@@@@#?77?B@@@&P?7#&J7?P&@&GJ77#@J?Y#@@@Y7??B@@@@@@@@@@@@@@@@5^~~!B@@@@@@@@&B5J?777??Y55?~7P&@@
~7?JY5PGBB##&&&&B~~^5@@@@@@@@@@@@@@@@@@@57?75@@@@&Y775?7?P&@&GJ77B@P7J5#@@@57?7G@@@@@@@@@@@@@@@@@?~~7?77777?JY!!YPGBBBG5!^~Y#@@@@@
^!7?J5PGBB##&&&&!^~!&@@@@@@@@@@@@@@@@@@B??7?#@@@@&GYJ?J5B&@@&5?7G@P7?YG&@@@Y7?7G@@@@@@@@@@@@@@@@@P~~!B#####BP?~7G&&&&&&J^?&@@@@@#P
:^!7?Y5PGBB##&&G^~^J@@@@@@@@@@@@@@@@@@@P7?7Y@@@@@@@&&&&&@@@@&P?7YJ7J5B&@@@@Y7?7G@@@@@@@@@@@@@@@@@#~~~B@@@@@@@@G~~B&&&#&Y^7&&#GJ!!?
.:^!7JY5PGB##&&Y^~^B@@@@@@@@@@@@@@@@@@@57?7G@@@@@@@@@@@@@@@@@#PYJYPB#@@@@@&?77J#@@@@@@@@@@@@@@@@@&7~~J@@@@@&#G?~?####BBB?~~~!?YB&@
..:^!7JYPGBB##&?^~~&@@@@@@@@@@@@@@@@@@&J77J&@@@@@@@@@@@@@@@@@@@&&&&@@@@@@@P777P@@@@@@@@@@@@@@@@@@@?~~~PG5J7!!7!~!77!!!!!7?YG&@@@@@
  .:^!7J5PGB##&?^^7&@@@@@@@@@@@@@@@@@@B777B@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B?77Y&@@@@@@@@@@@@@@@@@@@?~~~~?5GB&@@&&#####&&&@@@@@@&#G?
   .:^!7J5PGB##?^^7&@@@@@@@@@@@@@@@@@#?775@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#?77J#@@@@@@@@@@@@@@@@@@@@7~~~~?PB#&&&&&&&&&&&&&&#BPY?!~~7
    .:^!?Y5GB##?^^!&@@@@@@@@@@@@@@@@#J775&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#?77J#@@@@@@@@@@@@@@@@@@@@&!~~~~~!7!!!!!!!!!!!!!!~~!!7?JY55
     .:^!?YPGB#7^^~#@@@@@@@@@@@@@@@B?77P@@@@@@@@@@@@@@@@@@&G#@@@@@@@@@G?77Y#@@@@@@@@@@@@@@@@@@@@@G~~~~~~YGPP555555555555555555YJJ?
      .:^!?YPG#?^^^P@@@@@@@@@@@@@&P77Y#@@@@@@@@@@@&&@@@@@&P?G@@@@@@@&5777P&@@@@@@@@@@@@@@@@@@@@@@7~~~~~~YPPPPPPPPPP55555YYYJJ?77!~
       .:~7J5PBG^^^!&@@@@@@@@@&BY??5#@@@@@@&GB@@&B5G@@@@&P775&@@@@@#J77?G@@@@@@@@@@@@@@@@@@@@@@@P^~!~~~~YP555555555YYYJJ??77!~~^^:
        .:~7J5GBJ^^^P@@@@@@@@&Y7?5#@@@@@&#Y?G@@B5J7P@@&#P777Y&@@@&B?77?B@@@@@@@@@@@@@@@@@@@@@@@#~^?B~~~75555555YYYJJJ?77!!~^^::...
        ..:~7YPBG~^^~#@@@@@@&5?5B@@BPB&#57?#@&GY?77B@@&BJ!77J&@@&BJ77?B@@@@@@@@@@@@@@@@@@@@@@@#!~!&G~~~Y5555YYYJJ??77!~~^::....
         ..^!?YPBY^^^7&@@@@@#YP#@&YJG#P?7J#@&PJ?7?G@@@&GJ777J&@@#5?77G@@@@@@@@@@@@@@@@@@@@@@@#!^!#&~~~?555YYYJJ?77!~~^::...
          .:^!?5GBJ^~^?&@@@@@&@@&JY#BY77J&@&GJ?7JB@@@&#GJ7775@@&B5?7J&@@@@@@@@@@@@@@@@@@@@@@G~^7&@7~~!Y5YYYJ??7!!~^::...
           .:^!J5GB7^~^?&@@@@@@@&JG#G77?B@&#5??5&@@@@&BPY77?#@@&GY?7P@@@@@@@@@@@@@@@@@@@@@&J^~Y@@J^~~Y5YYJ??7!!~^::...
            .:^!?YPG!^~^!B@@@@@@&G#&#Y7Y&@&#J?B@@@@@@&BPY7?B@@@#PY?7B@@@@@@@@@@@@@@@@@@@@P~^7B@@J^~~JYYJJ?7!!~^::..
             ..:^~7Y5!^^^~J&@@@@@@@@@BJG@@&#G#@@@@@@@&BGYY#@@@@#P5??#@@@@@@@@@@@@@@@@@&G!^7B@@&J^^~JYJJ?7!!~^::..
                 .:~7Y?^^~^~J#@@@@@@@@&&@@@@@@@@@@@@@&##B&@@@@@&G5?J&@@@@@@@@@@@@@@@&P!^7G@@@#7^^!JYJ?77!~^::..
                   .:!JJ~^^~~~75#@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@&#BPB@@@@@@@@@@@@@&BJ~^?B@@@&5~^~?YJ7!~^:.....
                     .~?5J!^~~~~~75#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&GJ~^~Y#@@@#5~^^7?!:.
                      .^?PG57^~~~~~~~7YPB&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#GY7~^~JG&@@&#J^^^^^.
                       .^75B#5!~~~~!G#PJ7~!7J5GB#&&&@@@@@@@@@@@@@&&##G5J7~~~7JP#&@@@&G7^:^:.
                         .^7P#&G?~~!P#&@@&#G5?7!!!!!!!777777777!!~~^^~~7J5B&@@@@&#P?~:^~~.
                             .~YPPJ!~~~75G#&@@@@@&&##BGGPPP5555555PG#&&@@@@@@&B57^:^~!~:
                                  ..:::::^^~7JYPB#&&@@@@@@@@@@@@@@@@@@@&&#G5?~^^^~~^.
                                            ..::^^~~!7??JY55555PP55YJ7!~~^^^^^^^.
                                                  ........:::::::::::::::..
******/

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ERC721EnumerableV2.sol";

contract WallStBullsXStylesP is ERC721EnumerableV2, Ownable {
    uint256 public constant MAX_BULLS = 111;
    uint256 public constant PRICE = 0.420 ether;
    uint256 public constant RESERVED_BULLS = 11;
    uint256 public constant MAX_MINT = 3;

    mapping(address => uint256) public totalMinted;
    string public baseURI;
    bool public baseURIFinal;
    bool public publicSaleActive;
    bool public presaleActive;

    bytes32 private _presaleMerkleRoot;

    event BaseURIChanged(string baseURI);
    event PermanentURI(string _value, uint256 indexed _id);

    constructor(string memory _initialBaseURI) ERC721("Wall Street Bulls X Styles P", "WSBxSP")  {
        baseURI = _initialBaseURI;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        require(!baseURIFinal, "Base URL is unchangeable");
        baseURI = _newBaseURI;
        emit BaseURIChanged(baseURI);
    }

    function finalizeBaseURI() external onlyOwner {
        baseURIFinal = true;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function emitPermanent(uint256 tokenId) external onlyOwner {
        require(baseURIFinal, "Base URL must be finalized first");
        emit PermanentURI(tokenURI(tokenId), tokenId);
    }

    function togglePresaleActive() external onlyOwner {
        presaleActive = !presaleActive;
    }

    function togglePublicSaleActive() external onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

    function setPresaleMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        _presaleMerkleRoot = _merkleRoot;
    }

    function withdraw(address _to, uint256 _amount) external onlyOwner {
        (bool success, ) = _to.call{ value: _amount }("");
        require(success, "Failed to withdraw Ether");
    }

    function mintReserved(address _to, uint256 _bullCount) external onlyOwner {
        require(totalMinted[msg.sender] + _bullCount <= RESERVED_BULLS, "All Reserved Bulls have been minted");
        _mintBull(_to, _bullCount);
    }

    function _verifyPresaleEligible(address _account, uint8 _maxAllowed, bytes32[] calldata _merkleProof) private view returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(_account, _maxAllowed));
        return MerkleProof.verify(_merkleProof, _presaleMerkleRoot, node);
    }

    function mintBullPresale(uint256 _bullCount, uint8 _maxAllowed, bytes32[] calldata _merkleProof) external payable {
        require(presaleActive && !publicSaleActive, "Presale sale is not active");
        require(_verifyPresaleEligible(msg.sender, _maxAllowed, _merkleProof), "Address not found in presale allow list");
        require(totalMinted[msg.sender] + _bullCount <= uint256(_maxAllowed), "Purchase exceeds max presale mint count");
        require(PRICE * _bullCount == msg.value, "ETH amount is incorrect");

        _mintBull(msg.sender, _bullCount);
    }

    function mintBull(uint256 _bullCount) external payable {
        require(publicSaleActive, "Public sale is not active");
        require(totalMinted[msg.sender] + _bullCount <= MAX_MINT, "Purchase exceeds max mint count");
        require(PRICE * _bullCount == msg.value, "ETH amount is incorrect");

        _mintBull(msg.sender, _bullCount);
    }

    function _mintBull(address _to, uint256 _bullCount) private {
        uint256 totalSupply = totalSupply();
        require(totalSupply + _bullCount <= MAX_BULLS, "All Bulls have been minted. Hit the trading floor");
        require(_bullCount > 0, "Must mint at least one bull");

        for (uint256 i = 1; i <= _bullCount; i++) {
            totalMinted[msg.sender] += 1;
            _mint(_to, totalSupply + i);
        }
    }
}
