//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Masked is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 0.15 ether;
    uint256 public constant maxSupply = 100;
    uint256 public maxMintAmount = 100;
    bool public paused = false;
    mapping(address => bool) public whitelisted;
    address payable public payments;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        address _payments
    ) ERC721(_name, _symbol) {
        require(_payments != address(0), "Owner address");
        setBaseURI(_initBaseURI);
        payments = payable(_payments);
        mint(msg.sender, maxMintAmount);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(address _to, uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(!paused);
        require(_mintAmount > 0);
        require(_mintAmount <= maxMintAmount);
        require(supply + _mintAmount <= maxSupply);

        if (msg.sender != owner()) {
            if(!whitelisted[msg.sender]) {
                require(msg.value >= cost * _mintAmount);
            }
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_to, supply + i);
        }
    }

    function walletOfOwner(address _owner)
    view
    external
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
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
    }

    //only owner
    function setCost(uint256 _newCost) external onlyOwner {
        require(_newCost > 0);
        cost = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) external onlyOwner {
        require(_newmaxMintAmount > 0);
        maxMintAmount = _newmaxMintAmount;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        require(bytes(_newBaseURI).length > 0, "Empty base uri");
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) external onlyOwner {
        require(bytes(_newBaseExtension).length > 0, "Empty base extension");
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) external onlyOwner {
        paused = _state;
    }

    function whitelistUser(address _user) external onlyOwner {
        require(_user != address(0), "Owner address");
        whitelisted[_user] = true;
    }

    function removeWhitelistUser(address _user) external onlyOwner {
        require(_user != address(0), "Owner address");
        whitelisted[_user] = false;
    }

    function withdraw() external payable onlyOwner {
        (bool success, ) = payable(payments).call{value: address(this).balance}("");
        require(success);
    }

    function renounceOwnership() public view override onlyOwner {
        revert("can't renounceOwnership here"); //not possible with this smart contract
    }

}
