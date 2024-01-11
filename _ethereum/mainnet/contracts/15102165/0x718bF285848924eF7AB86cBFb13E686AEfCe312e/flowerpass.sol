// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

interface INFT {
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract FlowerPass is ERC721A, Ownable {
    using Strings for uint256;

    string  public baseTokenURI = "ipfs://bafkreidbx2olvhram2f75gy2sncv3hpnm3lr66gzvaagnirnfu6j55qnlm";
    string  public defaultTokenURI;
    uint256 public maxSupply = 2400;
    uint256 public peraccountlimit = 1;

    address public inft = 0x2eAcDaF1F9976fF06Ce164cbaECA459135713C1e;
    mapping(address => uint256) public userpassmintinfo;

    constructor() ERC721A("International Flower Pass", "IFP") {
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Must from real wallet address");
        _;
    }

    function mint() external callerIsUser payable  {
        require(totalSupply() + 1 <= maxSupply, "Exceed supply");
        uint holdernumber = INFT(inft).balanceOf(msg.sender);
        require(holdernumber >= 10, "Not hold enough");
        require(userpassmintinfo[msg.sender] < peraccountlimit, "Exceed account supply");
        _safeMint(msg.sender, 1);
        userpassmintinfo[msg.sender]+=1;
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = _baseURI();
        return
        bytes(currentBaseURI).length > 0 ? string(
            abi.encodePacked(
                currentBaseURI,
                tokenId.toString(),
                ".json"
            )
        ) : defaultTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setPeraccountlimit(uint  _accountlimit) external onlyOwner {
        peraccountlimit = _accountlimit;
    }

    function setBaseURI(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setDefaultURI(string calldata _defaultURI) external onlyOwner {
        defaultTokenURI = _defaultURI;
    }

    function setMaxSupply(uint  _maxnumber) external onlyOwner {
        maxSupply = _maxnumber;
    }


    function setInft(address  _nft) external onlyOwner {
        inft = _nft;
    }

    function withdrawMoney() external onlyOwner {
        (bool success,) = msg.sender.call{value : address(this).balance}("");
        require(success, "Transfer failed.");
    }

}

