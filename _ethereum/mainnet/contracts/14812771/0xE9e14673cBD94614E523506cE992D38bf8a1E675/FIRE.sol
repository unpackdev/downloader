// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
// import "./console.sol";

contract FIRE is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;

    string baseURI;
    string public baseExtension = "";
    string public notRevealedUri;

    uint256 public maxSupply = 335;
    uint256 public cost = 0.3 ether;
    uint256 public whiteListCost = 0.3 ether;

    mapping(address => bool) public whiteList;

    bool public paused = false;
    bool public revealed = false;
    bool private lock = true;

    uint256 public whiteListStartTime = 1653094800;
    uint256 public whiteListEndTime = 1653138000;

    address public devteam;
    address public operator;

    constructor (
        string memory _initNotRevealedUri,
        address _operator,
        address _devteam
    ) ERC721("FIRE NFT", "FIRE") {
        devteam = _devteam;
        operator = _operator;

        setNotRevealedURI(_initNotRevealedUri);

        _safeMint(0xFAFb15E12846d95eFA31e347da6ade77a68c71a2, 1);
        _safeMint(0x0aA18f119BB6053C64de6857bd9e61ED204B2952, 2);
        _safeMint(0xa9f715cdF6b1fdf88e0f465CbB289a908fd20648, 3);
        _safeMint(0x72D8Ac7896fDBC80A204E3Bb741A039890Ffd831, 4);
        _safeMint(0x0A8F4C21A980b0A76b4f7071CB4713d8a74753F1, 5);
        _safeMint(0x25B43cf78C969D11a093BC838E16750579c492cb, 6);
        _safeMint(0xA58C9Fd88A71cb0E861E92a117C04daC354613A8, 7);
        _safeMint(0x0689Ffa5dd8F13c38dF446c8AbAf55B38Bd91CfE, 8);
        _safeMint(0x97136c9315821C85224C216bB1AA0cF63B0E9e87, 9);
        _safeMint(0x24E4F4C4Ec4eC1eD04d728EF7D8b7923386e82c9, 10);
        _safeMint(0x1bEfa7EE8828f1918C5a5115d628F504fB1F7dE3, 11);
        _safeMint(0x1bEfa7EE8828f1918C5a5115d628F504fB1F7dE3, 12);
        _safeMint(0x1F4450E3432A9d84b19BcC6AF5b156e1211c166F, 13);
        _safeMint(0x8bDD8c53d05ec982d500d8FBa0C9370B36AC5222, 14);
        _safeMint(0xdDFAe26b1a405e62Ad17f9d2963B858CDD49859c, 15);
        _safeMint(0x2Ba981545C6C9cbbcdA365F289eDfa6AAdCEcE9E, 16);
        _safeMint(0xDfEb1dE4C6519a514EB05dA328183f2292db2Cf3, 17);

    }

    function setWhiteList(address[] calldata _whiteList) external onlyOwner {
        for (uint i = 0; i < _whiteList.length; i++) {
          whiteList[_whiteList[i]] = true;
        }
    }

    function mint(uint256 _mintAmount) public payable {
        require(!paused, "FIRE: Minting is temporary close");
        require(_mintAmount > 0, "FIRE: qty should gte 0");
        uint256 _supply = totalSupply();
        require(_supply + _mintAmount <= maxSupply, "FIRE: Achieve max supply");

        _publicOffering(_mintAmount);

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_msgSender(), _supply + i);
        }
    }

    function setWhiteListTime(uint256 _startTime, uint256 _endTime) public onlyOwner {
        whiteListStartTime = _startTime;
        whiteListEndTime = _endTime;
    }

    function setCost(uint256 _cost, uint256 _whiteListCost) public onlyOwner {
        cost = _cost;
        whiteListCost = _whiteListCost;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setRevealedWithURI(bool _isOpen, string memory _URI, string memory _baseExtension) public onlyOwner {
        revealed = _isOpen;
        baseURI = _URI;
        baseExtension = _baseExtension;
    }

    function flipReveal() public onlyOwner {
        revealed = !revealed;
    }

    function flipPause() public onlyOwner {
        paused = !paused;
    }

    function flipLock() public onlyDevTeam {
        lock = !lock;
    }

    function withdraw() public onlyOwner {
        require(!lock, "FIRE: Lock");
        // 100% to operator
        (bool sendToOperator, ) = payable(operator).call{ value: address(this).balance }("");
        require(sendToOperator, "FIRE: Fail to withdraw to operator");
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();

        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
    }

    function _publicOffering(uint256 _mintAmount) internal {
        require(block.timestamp >= whiteListStartTime, "FIRE: Not start sell yet");
        if (block.timestamp >= whiteListStartTime && block.timestamp <= whiteListEndTime) {
            // Presale
            require(msg.value >= whiteListCost * _mintAmount, "FIRE: Insufficient balance");
            require(whiteList[_msgSender()], "FIRE: You are not in the whiteList");
            require(_mintAmount == 1 && balanceOf(_msgSender()) < 1, "FIRE: Can only mint 1 NFT during whiteList time");
        } else {
            // public sale
            require(msg.value >= cost * _mintAmount, "FIRE: Insufficient balance");
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    modifier onlyDevTeam() {
        require(devteam == _msgSender(), "FIRE: caller is not the devTeam");
        _;
    }

}
