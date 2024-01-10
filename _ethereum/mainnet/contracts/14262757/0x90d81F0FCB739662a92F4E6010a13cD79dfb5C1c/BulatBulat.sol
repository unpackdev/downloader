// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract BulatBulat is ERC721Enumerable, Ownable {
    using Strings for uint256;
    string public baseURI =
        "https://storage.googleapis.com/artjam-dapp.appspot.com/metadata/";
    string public baseExtension = ".json";
    uint256 public maxSupply = 1100;
    uint256 public maxMintAmountPerTx = 10;
    uint256 public stage = 0;
    uint256 nonce = 0;

    struct Stage {
        uint256 cost;
        uint256 maxSupply;
        uint256 maxMintAmount;
        uint256 mintCounter;
        bool whitelistFlag;
        // mapping(address => bool) whitelisted;
        // mapping(address => uint256[]) buyer;
    }
    struct Whitelist {
        mapping(address => bool) whitelisted;
    }
    struct Buyer {
        mapping(address => uint256[]) token;
    }

    mapping(uint256 => Stage) stages;
    mapping(uint256 => Whitelist) whitelisteds;
    mapping(uint256 => Buyer) buyers;
    uint256[] edition_enrolled;

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {
        stages[1] = Stage({
            cost: 0.00 ether,
            maxSupply: 100,
            maxMintAmount: 1,
            mintCounter: 0,
            whitelistFlag: true
        });
        stages[2] = Stage({
            cost: 0.1 ether,
            maxSupply: 300,
            maxMintAmount: 1,
            mintCounter: 0,
            whitelistFlag: true
        });
        stages[3] = Stage({
            cost: 0.1 ether,
            maxSupply: 400,
            maxMintAmount: 3,
            mintCounter: 0,
            whitelistFlag: true
        });
        stages[4] = Stage({
            cost: 0.1 ether,
            maxSupply: 200,
            maxMintAmount: 1,
            mintCounter: 0,
            whitelistFlag: true
        });
        stages[5] = Stage({
            cost: 0.15 ether,
            maxSupply: 0,
            maxMintAmount: 5,
            mintCounter: 0,
            whitelistFlag: false
        });
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    // public
    function mint(address _to, uint256 _amount) public payable {
        uint256 supply = totalSupply();
        require(stage > 0, "Sale is paused or not ready");
        require(supply < maxSupply, "No more token");
        require(_amount > 0, "Invalid mint amount");
        require(_amount <= edition_enrolled.length, "Out of editions");
        require(_amount <= maxMintAmountPerTx, "Max 10 mint per transaction");

        if (stages[stage].maxSupply > 0) {
            require(
                _amount <= stages[stage].maxSupply - stages[stage].mintCounter,
                "Out of tokens"
            );
        }

        if (msg.sender != owner()) {
            if (stages[stage].whitelistFlag) {
                require(
                    whitelisteds[stage].whitelisted[msg.sender] == true,
                    "Address is not whitelisted"
                );
            }

            if (stages[stage].maxMintAmount > 0) {
                require(
                    _amount <=
                        (stages[stage].maxMintAmount -
                            buyers[stage].token[msg.sender].length),
                    "Quota exceeded"
                );
            }

            if (stages[stage].cost > 0) {
                require(
                    msg.value >= stages[stage].cost * _amount,
                    "Not enough ETH sent; check price!"
                );
            }
        }

        for (uint256 i = 1; i <= _amount; i++) {
            uint256 randomnumber = uint256(
                keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))
            ) % edition_enrolled.length;
            nonce++;
            uint256 _t = edition_enrolled[randomnumber];

            buyers[stage].token[msg.sender].push(_t);
            stages[stage].mintCounter += 1;

            edition_enrolled[randomnumber] = edition_enrolled[
                edition_enrolled.length - 1
            ];
            edition_enrolled.pop();

            _safeMint(_to, _t);
        }
    }

    function editionEnrolled() public view returns (uint256) {
        return edition_enrolled.length;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function verify(uint256 _amount) public view returns (uint256) {
        if (stage > 0) {
            if (totalSupply() < maxSupply) {
                if (_amount > 0) {
                    if (_amount <= edition_enrolled.length) {
                        if (stages[stage].maxSupply > 0) {
                            if (
                                _amount <=
                                stages[stage].maxSupply -
                                    stages[stage].mintCounter
                            ) {} else {
                                return 5;
                            }
                        }

                        if (msg.sender != owner()) {
                            if (stages[stage].whitelistFlag) {
                                if (
                                    whitelisteds[stage].whitelisted[
                                        msg.sender
                                    ] == true
                                ) {} else {
                                    return 6;
                                }
                            }

                            if (stages[stage].maxMintAmount > 0) {
                                if (
                                    _amount <=
                                    (stages[stage].maxMintAmount -
                                        buyers[stage].token[msg.sender].length)
                                ) {} else {
                                    return 7;
                                }
                            }

                            return 0;
                        } else {
                            return 0;
                        }
                    } else {
                        return 4;
                    }
                } else {
                    return 3;
                }
            } else {
                return 2;
            }
        } else {
            return 1;
        }
    }

    function whitelistUser(uint256 _stage, address _user) public onlyOwner {
        whitelisteds[_stage].whitelisted[_user] = true;
    }

    function removeWhitelistUser(uint256 _stage, address _user)
        public
        onlyOwner
    {
        whitelisteds[_stage].whitelisted[_user] = false;
    }

    function genEdition() public onlyOwner {
        if (edition_enrolled.length == 0) {
            for (uint256 i = 1; i <= maxSupply; i++) {
                edition_enrolled.push(i);
            }
        }
    }

    function setEdition(uint256 _t) public onlyOwner {
        if (stage == 0) {
            edition_enrolled.push(_t);
        }
    }

    function setStage(uint256 _stage) public onlyOwner {
        stage = _stage;
    }

    function setStageConfig(
        uint256 _stage,
        uint256 _cost,
        uint256 _maxSupply,
        uint256 _maxMintAmount
    ) public onlyOwner {
        stages[_stage].cost = _cost;
        stages[_stage].maxSupply = _maxSupply;
        stages[_stage].maxMintAmount = _maxMintAmount;
    }

    function getStageConfig(uint256 _stage)
        public
        view
        onlyOwner
        returns (Stage memory)
    {
        return stages[_stage];
    }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}
