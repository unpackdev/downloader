// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

/*

██████╗░███████╗██████╗░░█████╗░██████╗░███╗░░██╗  ░█████╗░██████╗░███████╗  ██╗░░██╗██╗███╗░░██╗░██████╗░
██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔══██╗████╗░██║  ██╔══██╗██╔══██╗██╔════╝  ██║░██╔╝██║████╗░██║██╔════╝░
██████╔╝█████╗░░██████╦╝██║░░██║██████╔╝██╔██╗██║  ███████║██████╔╝█████╗░░  █████═╝░██║██╔██╗██║██║░░██╗░
██╔══██╗██╔══╝░░██╔══██╗██║░░██║██╔══██╗██║╚████║  ██╔══██║██╔═══╝░██╔══╝░░  ██╔═██╗░██║██║╚████║██║░░╚██╗
██║░░██║███████╗██████╦╝╚█████╔╝██║░░██║██║░╚███║  ██║░░██║██║░░░░░███████╗  ██║░╚██╗██║██║░╚███║╚██████╔╝
╚═╝░░╚═╝╚══════╝╚═════╝░░╚════╝░╚═╝░░╚═╝╚═╝░░╚══╝  ╚═╝░░╚═╝╚═╝░░░░░╚══════╝  ╚═╝░░╚═╝╚═╝╚═╝░░╚══╝░╚═════╝░

*/
contract RebornApeKing is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    uint256 public mintPrice;
    uint256 public maxApePurchase;
    uint256 public maxSupply;

    bool public isPresale;
    bool public isPublicSale;

    mapping(address => bool) whitelisted;

    string private _uri;

    constructor(string memory uri_) ERC721("The Reborn Ape King", "RAK") {
        mintPrice = 72000000000000000; // 0.072 ETH
        maxApePurchase = 20;
        maxSupply = 12000;

        _uri = uri_;
    }

    ///@dev Get the array of token for owner.
    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 index; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    ///@dev Return the base uri
    function baseURI() public view returns (string memory) {
        return _uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    ///@dev Set the base uri
    function setBaseURI(string memory _newUri) external onlyOwner {
        _uri = _newUri;
    }

    ///@dev Check if certain token id is exists.
    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    ///@dev Set price to mint an ape king.
    function setMintPrice(uint256 _price) external onlyOwner {
        mintPrice = _price;
    }

    ///@dev Set maximum count to mint per once.
    function setMaxToMint(uint256 _maxMint) external onlyOwner {
        maxApePurchase = _maxMint;
    }

    ///@dev Set maxsupply
    function setMaxSupply(uint256 _max) external onlyOwner {
        maxSupply = _max;
    }

    function startPresale() external onlyOwner {
        require(isPublicSale == false, "public sale is already live");
        isPresale = true;
    }

    function endPresale() external onlyOwner {
        require(isPresale == true, "presale is not started");
        isPresale = false;
    }

    function startPublicSale() external onlyOwner {
        require(isPresale == false, "presale is live");
        isPublicSale = true;
    }

    function whitelistUsers(address[] calldata _users) external onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            whitelisted[_users[i]] = true;
        }
    }

    ///@dev mint ape kings
    function mintApeKing(uint256 numberOfTokens) external payable {
        require(isPublicSale || isPresale, "Sale must be active to mint");

        require(numberOfTokens <= maxApePurchase, "Invalid amount to mint per once");
        require(totalSupply().add(numberOfTokens) <= maxSupply, "Purchase would exceed max supply");
        require(mintPrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");

        if (isPresale) {
            require(whitelisted[msg.sender] == true, "you are not whitelisted for the presale");
        }

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < maxSupply) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    ///@dev Reserve Ape Kings by owner
    function reserveApes(address _to, uint256 _numberOfTokens) external onlyOwner {
        require(_to != address(0), "Invalid address");

        uint256 supply = totalSupply();

        for (uint256 i = 0; i < _numberOfTokens; i++) {
            _safeMint(_to, supply + i);
        }
    }

    ///@dev take eth out of the contract
    function withdraw(address to) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(to).transfer(balance);
    }

    function giveAwayETH(address[] calldata _to, uint256 amount) external onlyOwner {
        for (uint256 i = 0; i < _to.length; i++) {
            payable(_to[i]).transfer(amount);
        }
    }
}
