// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./ERC721A.sol";

contract DreamGarageVIP is ERC721A, Ownable {

    uint256 MAX_MINT = 3;
    uint256 PROFIT = 5;
    uint256 public MAX_TOTAL = 540;
    uint256 public price = 0.35 ether;
    uint256 public mintTime = 1646917200;
    string baseTokenURI;

    address withdrawAddress;
    address stevenAddress = 0xAc4Ff7E04ce061826AAD93f826509D3d9E96682D;

    constructor() ERC721A("DreamGarageVIP", "DGV")  {
        withdrawAddress = msg.sender;
        setBaseURI("https://badgameshow.com/dreamGarage/metadata/");
        getAirDropNFT();
    }

    function mint(uint256 num) public payable {
        uint256 supply = totalSupply();
        require(num <= MAX_MINT, "You can adopt a maximum of MAX_MINT Cats");
        require(supply + num <= MAX_TOTAL, "Exceeds maximum Cats supply");
        require(msg.value >= price * num, "Ether sent is not correct");
        require(buyAmount[msg.sender] + num <= 3, "You can only mint three NFT");
        require(block.timestamp >= mintTime, "no mint time");

        _safeMint(msg.sender, num);
    }

    function setWithdrawAddress(address _newAddress) public onlyOwner {
        withdrawAddress = _newAddress;
    }

    function setMintTime(uint256 _mintTime) public onlyOwner {
        mintTime = _mintTime;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function withdrawAll() public onlyOwner {
        uint one = address(this).balance * (100 - PROFIT) / 100;
        uint two = address(this).balance * PROFIT / 100;
        require(payable(withdrawAddress).send(one));
        require(payable(stevenAddress).send(two));
    }

    function getAirDropNFT() private {
        _safeMint(0xD35104CbDF89004bAA88872235e44302d5372800, 3);
        _safeMint(0x635326727F62c591FEeCaa59ABD85B717aF41780, 1);
        _safeMint(0x64f9606C333CA62edf95Ea347f30db10306A3ad1, 1);
        _safeMint(0x02fa786D65d44ba823908595D6024D069BADb51D, 1);
        _safeMint(0x6C9DD3A0E2a0116FF84fca8B5304aF22AbEf6e8b, 1);
        _safeMint(0xA9906518E84F53E19da741bf5f671efde090aE60, 1);
        _safeMint(0x67c56150Ed41c097576cb866fD314d57B4422a48, 1);
        _safeMint(0x474ef1bBe5F9F861440B67D2f65981a96565D2C0, 1);
        _safeMint(0xE6F255ea5F5697fb6271b699e6Dc9a8107F7F031, 1);
        _safeMint(0xC491BB4e914c6BBe41f064bCF8E2211461187498, 1);
        _safeMint(0x6df3eE0902f6C98b2ff0C579AEcC1B760c4B3B4c, 1);
        _safeMint(0x2f20D2648dEcA646fDE1F2DC414c6ef01C27cD32, 1);
        _safeMint(0xa05AD78F74929790186C720a156438E08D0379dc, 1);
        _safeMint(0x7940450e9186669BED08A1c29e44D197ba3619B9, 1);
        _safeMint(stevenAddress, 1);
        _safeMint(0x1D0363e443cab13c6771150913D017AfD77BBFf6, 3);
    }

    function walletOfOwner(address owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokensId = new uint256[](tokenCount);

        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokensId;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
}