// SPDX-License-Identifier: MIT

/* Twitter: @OongaNFT

^^^^^^^^^^^^^^^::^!?J5PB#&@@@&&&&&&####BGP555P&@5^!YB@@5^~~~~~~~~~~~~~~~!!~~~~~~
J7~^:::^^^^^:^!JP#&@&&#BBGPPPP55555555555555P&@@GG#&BB@G~77!~~~~!7?7!~~7J?7~~~~~
&&#BPY?7!~~!YB@@&#GP5555555555555555555555555GGGGGPPG&@577???J5P5J?5G5!~!!~~~~!?
5PGB#&&&&&&&@&BP55555555555555555555555555555555555#&##&&&#PYJ!:    :#@Y~~~~~~??
55555555PPPP5555555555555555555555555555555555555555555PG&@#J.      J&5&Y~~~~~~~
5555555555555555555555555555555555555555555555555555555555P#@&J. :?B#?^J#~~~~~~~
5555555555P55555555555PGB55555555555555555555555555555555555P#@#BBGJ~^^5B~~~~~~~
5555555G#&&##BGGGGGGB#&@#P555555555555555555555555555555555555G&@B!^^~Y&7~7J?!~~
55555P#@&@&GGB#######BGP5555555555555555555555555555555555555555#@&JY##?~~!7!~~~
55555&@G~JB@&BGP5555555555555555555555555555555555555555555555555G@@#J~~~~~~~!!~
5555G@@7^^~75B&@&&#BBGGP555555555555555555555555555555555555555555G@@Y~!~~~~!?!~
5555P@@5^^~^^^!?YPB####&&BP5555555555555555555555555555555555555555G@@Y77!~~~~~~
55555G@@5!^^^~~^^^^~~~~!B@&P5555555555555555555555555555555555555555GBG5J!~~~~~~
555555P#@&P?!~^^^^^^^~!J#@#5555555555555555555555555555555555555555555P#@&G7~~~~
55555555PB&@&#GP555PGB&@#G5555555555555555555555555555555555555555555555PB@&Y~!7
55555555555PGBB##&###BGP555555555555555555555555555555555555555555555PGGP5G@@57?
5555555555555555555555555555555555P##&#G555555555555555555555555555P&@@@@#5G@@Y~
555555555555555555555555555555555G@@@@@@#55555555555555555555555555#@@@@@@G5B@&7
555555555555555555555555555555555G@@@@@@#55555555555555555555555555P#&@@&B55P&@5
5555555555555555555555555555555555PB###G555555555555555555555555555555PP55555#@#
55555555555555555555555555555555555555555555555555555555555PPP555555555555555B@&
5555555555555555555555555555555555555555555555PB####BGPPB###B#&B5555555555555B@&
555555555555555555555555555555555555555555555P&#5JJYPBBBG5?7!!J&&555555555555#@B
555555555555555555555555555555555555555555555&&7!!77777!!!!!!!!J@#5555555555P@@Y
55555555555555555555555555555555555555555555P@#PBBBBBBBBG5Y?!!!!#&5555555555#@#^
55555555555555555555555555555555555555555555P@@P7~^^^^~~7?5B#57?@#555555555B@&!.
555555555555555555555555555555555555555555555G@P^::::::::::^J&##&P55555555#@#~..
5555555555555555555555555555555555555555555555G&#Y!^:::::::^!G@#P5555555G&@G~::.
555555555555555555555555555555555555555555555555G#&FUCKYOUB&BP5555555P#@#?::^:.
555555555555555555555555555555555555555555555555555PGBBBBBGP5555555PG&@#J:......
5555555555555555555555555555555555555555555555555555555555555555PG#@@G?:..:.....
5555555555555555555555555555555555555555555555555555555555555PB&@&GJ^......:!!~:
55555555555555555555555555555555555555555555555555555555PGB#&&B57^.........:^^^.
55555555555555555555555555555555555555555555555555PPGB#&@&&@@G?^................
555555555555555555555555555555555555555555PPGBB#&&@@@@B5?7!?YG#&BP~.............
555555555555555555555555555PPPPGGGBB##&&&@@&##BG5Y5&@@&#G5?!!5G&@@G::::.........
##########BBBBBB####&&&&&&&&&&&##BBGP5Y??B@#PJ7!!!!75&@@##@#B@@G!~^~^:..:::.....
GBPPPPPPPPPPPPPP555YYYJJ?77!~!!~^:.......:7P#@&#P?YGP#@B!:!YPPY^.......^~~~:....
*/

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract Oonga is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public uriPrefix;

    address public proxyRegistryAddress;

    uint256 public price;
    uint256 public maxSupply;
    uint256 public maxFreeSupply;
    uint256 public maxMintAmountPerTx;
    uint256 public maxMintAmountPerWallet;

    uint256 public constant RESERVES = 100;

    bool public paused = true;
    bool public reservesCollected = false;

    constructor(
        uint256 _price,
        uint256 _maxSupply,
        uint256 _maxFreeSupply,
        uint256 _maxMintAmountPerTx,
        uint256 _maxMintAmountPerWallet,
        string memory _uriPrefix
    ) ERC721A("Oonga", "OONGA") {
        setPrice(_price);
        maxSupply = _maxSupply;
        maxFreeSupply = _maxFreeSupply;
        setMaxMintAmountPerTx(_maxMintAmountPerTx);
        setMaxMintAmountPerWallet(_maxMintAmountPerWallet);
        setUriPrefix(_uriPrefix);
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        require(
            _numberMinted(msg.sender) + _mintAmount <= maxMintAmountPerWallet,
            "Wallet limit reached!"
        );
        _;
    }

    function mint(uint256 _mintAmount)
        public
        payable
        mintCompliance(_mintAmount)
    {
        require(!paused, "The contract is paused!");
        uint256 cost = price;
        bool isFree = totalSupply() + _mintAmount < maxFreeSupply + 1;
        if (isFree) {
            cost = 0;
        }
        require(msg.value >= _mintAmount * cost, "Insufficient funds!");

        _safeMint(_msgSender(), _mintAmount);
    }

    function collectReserves() external onlyOwner {
        require(!reservesCollected, "Reserves already taken.");
        _safeMint(_msgSender(), RESERVES);
        reservesCollected = true;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = _startTokenId();
        uint256 ownedTokenIndex = 0;
        address latestOwnerAddress;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId < _nextTokenId()
        ) {
            TokenOwnership memory ownership = _ownershipOf(currentTokenId);

            if (!ownership.burned) {
                if (ownership.addr != address(0)) {
                    latestOwnerAddress = ownership.addr;
                }

                if (latestOwnerAddress == _owner) {
                    ownedTokenIds[ownedTokenIndex] = currentTokenId;

                    ownedTokenIndex++;
                }
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setMaxMintAmountPerWallet(uint256 _maxMintAmountPerWallet)
        public
        onlyOwner
    {
        maxMintAmountPerWallet = _maxMintAmountPerWallet;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "Failed to withdraw balance.");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}
