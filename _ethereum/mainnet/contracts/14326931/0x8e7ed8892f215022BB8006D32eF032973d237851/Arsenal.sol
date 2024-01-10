// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
// import "./console.sol";

/**
    🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦

    /$$   /$$/$$                       /$$                          /$$$$$$                                              /$$
    | $$  | $| $$                      |__/                         /$$__  $$                                            | $$
    | $$  | $| $$   /$$ /$$$$$$ /$$$$$$ /$$/$$$$$$$  /$$$$$$       | $$  \ $$ /$$$$$$  /$$$$$$$ /$$$$$$ /$$$$$$$  /$$$$$$| $$
    | $$  | $| $$  /$$//$$__  $|____  $| $| $$__  $$/$$__  $$      | $$$$$$$$/$$__  $$/$$_____//$$__  $| $$__  $$|____  $| $$
    | $$  | $| $$$$$$/| $$  \__//$$$$$$| $| $$  \ $| $$$$$$$$      | $$__  $| $$  \__|  $$$$$$| $$$$$$$| $$  \ $$ /$$$$$$| $$
    | $$  | $| $$_  $$| $$     /$$__  $| $| $$  | $| $$_____/      | $$  | $| $$      \____  $| $$_____| $$  | $$/$$__  $| $$
    |  $$$$$$| $$ \  $| $$    |  $$$$$$| $| $$  | $|  $$$$$$$      | $$  | $| $$      /$$$$$$$|  $$$$$$| $$  | $|  $$$$$$| $$
    \______/|__/  \__|__/     \_______|__|__/  |__/\_______/      |__/  |__|__/     |_______/ \_______|__/  |__/\_______|__/

    🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦 🇺🇦
**/
contract Arsenal is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    uint256 public MAXSUPPLY = 250_000;
    uint256 public cost = 0.1 ether;
    // init 0.6 Ether is to adjust number after premint
    uint256 public receivedDonate = 0.6 ether;
    string private baseURI;
    bool public paused = false;
    address private Ukraine = 0x165CD37b4C644C2921454429E7F9358d18A45e14;

    event MessageToUkraine(address sender, string message);

    constructor (string memory _URI) ERC721("Ukraine Arsenal", "UARSL") {
        baseURI = _URI;

        for (uint256 i = 1; i <= 6; i++) {
            _safeMint(Ukraine, i);
        }
    }

    function mint(uint256 _mintAmount, address _to, string memory _message) public payable {
        uint256 _supply = totalSupply();
        require(!paused, "Arsenal: Minting is temporary close");
        require(_mintAmount > 0, "Arsenal: qty should gte 0");
        require(_supply + _mintAmount <= MAXSUPPLY, "Arsenal: Achieve max supply");
        require(msg.value >= cost.mul(_mintAmount), "Arsenal: Insufficient balance");
        // 10% to team
        uint toTeamQty = msg.value.div(10);
        (bool sendDevteam, ) = payable(owner()).call{ value: toTeamQty }("");
        require(sendDevteam, "Arsenal: Fail to send Devteam");
        // 90% to Ukraine Crypto Donation
        // https://etherscan.io/tokenholdings?a=0x165CD37b4C644C2921454429E7F9358d18A45e14
        (bool sendOperator, ) = payable(Ukraine).call{ value: msg.value.sub(toTeamQty) }("");
        require(sendOperator, "Arsenal: Fail to send Ukraine");

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_to, _supply + i);
        }

        if (bytes(_message).length > 0) {
            emit MessageToUkraine(_msgSender(), _message);
        }

        receivedDonate += msg.value;
    }

    function flipPause() public onlyOwner {
        paused = !paused;
    }

    function setCost(uint _cost) public onlyOwner {
        cost = _cost;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}
