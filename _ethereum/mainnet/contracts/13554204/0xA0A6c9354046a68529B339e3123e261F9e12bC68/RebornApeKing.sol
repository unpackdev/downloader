// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./MinterRole.sol";
import "./IYieldProxy.sol";

/*

██████╗░███████╗██████╗░░█████╗░██████╗░███╗░░██╗  ░█████╗░██████╗░███████╗  ██╗░░██╗██╗███╗░░██╗░██████╗░
██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔══██╗████╗░██║  ██╔══██╗██╔══██╗██╔════╝  ██║░██╔╝██║████╗░██║██╔════╝░
██████╔╝█████╗░░██████╦╝██║░░██║██████╔╝██╔██╗██║  ███████║██████╔╝█████╗░░  █████═╝░██║██╔██╗██║██║░░██╗░
██╔══██╗██╔══╝░░██╔══██╗██║░░██║██╔══██╗██║╚████║  ██╔══██║██╔═══╝░██╔══╝░░  ██╔═██╗░██║██║╚████║██║░░╚██╗
██║░░██║███████╗██████╦╝╚█████╔╝██║░░██║██║░╚███║  ██║░░██║██║░░░░░███████╗  ██║░╚██╗██║██║░╚███║╚██████╔╝
╚═╝░░╚═╝╚══════╝╚═════╝░░╚════╝░╚═╝░░╚═╝╚═╝░░╚══╝  ╚═╝░░╚═╝╚═╝░░░░░╚══════╝  ╚═╝░░╚═╝╚═╝╚═╝░░╚══╝░╚═════╝░

*/
contract RebornApeKing is ERC721Enumerable, Ownable, MinterRole {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public mintPrice;

    uint256 public normalMaxSupply;
    uint256 public premiumMaxSupply;

    bool public presaleStarted;
    bool public publicSaleStarted;
    bool public presaleEnded;

    uint256 public normalMinted;
    uint256 public premiumMinted;

    uint256 public maxApePurchase;
    uint256 public premiumMaxApePurchase;
    uint256 public premiumMaxApeMintPerOneAddress;

    bool public stopPremiumsale;

    mapping(address => bool) public whitelisted;

    mapping(address => uint256) public premiumPurchased;

    address public dogePound = 0xF4ee95274741437636e748DdAc70818B4ED7d043;
    address public bayc = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;
    address public coolcats = 0x1A92f7381B9F03921564a437210bB9396471050C;
    address public mekaverse = 0x9A534628B4062E123cE7Ee2222ec20B86e16Ca8F;

    string private _uri;

    mapping(uint256 => string) public specialURI;

    address public proxy;

    uint256 public saleBreakPoint;

    constructor(string memory uri_) ERC721("Reborn Ape King", "RAK") {
        mintPrice = 72000000000000000;

        maxApePurchase = 5;
        premiumMaxApePurchase = 2;

        normalMaxSupply = 9800;
        premiumMaxSupply = 200;
        premiumMaxApeMintPerOneAddress = 5;
        saleBreakPoint = 3000;

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

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (tokenId < 10000) {
            return bytes(_uri).length > 0 ? string(abi.encodePacked(_uri, tokenId.toString())) : "";
        } else return bytes(specialURI[tokenId]).length > 0 ? specialURI[tokenId] : "";
    }

    ///@dev Return the base uri
    function baseURI() public view returns (string memory) {
        return _uri;
    }

    ///@dev Set the base uri
    function setBaseURI(string memory _newUri) external onlyOwner {
        _uri = _newUri;
    }

    function setSpecialURI(uint256 _tokenId, string memory _newURI) external onlyOwner {
        if (_tokenId >= 10000) specialURI[_tokenId] = _newURI;
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

    function setPremiumMaxToMint(uint256 _maxMint) external onlyOwner {
        premiumMaxApePurchase = _maxMint;
    }

    function setPremiumMaxSupply(uint256 _max) external onlyOwner {
        premiumMaxSupply = _max;
    }

    function setMaxPerAddress(uint256 _max) external onlyOwner {
        premiumMaxApeMintPerOneAddress = _max;
    }

    function setStopPremiumsale(bool _stop) external onlyOwner {
        stopPremiumsale = _stop;
    }

    function setNormalMaxSupply(uint256 _max) external onlyOwner {
        normalMaxSupply = _max;
    }

    function setSaleBreakPoint(uint256 _break) external onlyOwner {
        saleBreakPoint = _break;
    }

    function startPresale() external onlyOwner {
        require(publicSaleStarted == false, "public sale is already live");
        require(presaleEnded == false, "presale is already ended");
        presaleStarted = true;
    }

    function endPresale() external onlyOwner {
        require(presaleStarted == true, "presale is not started");
        presaleStarted = false;
        presaleEnded = true;
    }

    function startPublicSale() external onlyOwner {
        require(presaleEnded == true, "presale isn't ended yet");
        publicSaleStarted = true;
    }

    function whitelistUsers(address[] calldata _users) external onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            whitelisted[_users[i]] = true;
        }
    }

    function removeUsersFromWhiteList(address[] calldata _users) external onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            whitelisted[_users[i]] = false;
        }
    }

    function giveAwayApeKing(address[] calldata _users) external onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            uint256 mintIndex = totalSupply();
            if (normalMinted < normalMaxSupply) {
                normalMinted += 1;
                _updateAndMint(_users[i], mintIndex);
            }
        }
    }

    function mintSpecial(address _to, uint256 _count) external payable onlyMinter {
        if (totalSupply() >= 10000) {
            for (uint256 i = 0; i < _count; i++) {
                uint256 mintIndex = totalSupply();
                _updateAndMint(_to, mintIndex);
            }
        }
    }

    function mintApeKing(uint256 numberOfTokens) external payable {
        require(publicSaleStarted || presaleStarted, "Sale must be active to mint");

        require(totalSupply().add(numberOfTokens) <= saleBreakPoint, "exceed the sale break point");
        require(numberOfTokens <= maxApePurchase, "Invalid amount to mint per once");
        require(normalMinted.add(numberOfTokens) <= normalMaxSupply, "Purchase would exceed max supply");

        require(mintPrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");

        if (presaleStarted) {
            require(whitelisted[msg.sender] == true, "you are not whitelisted for the presale");
        }

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply();
            if (normalMinted < normalMaxSupply) {
                normalMinted += 1;
                _updateAndMint(msg.sender, mintIndex);
            }
        }
    }

    function mintApeKingPremium(uint256 numberOfTokens) external payable {
        require(stopPremiumsale == false, "Premium sale is stopped");
        require(isEligableForPremium(msg.sender) == true, "you are not eligable for premium mint");

        require(publicSaleStarted || presaleStarted, "Sale must be active to mint");
        require(totalSupply().add(numberOfTokens) <= saleBreakPoint, "exceed the sale break point");

        require(numberOfTokens <= premiumMaxApePurchase, "Invalid amount to mint per once");
        require(premiumMinted.add(numberOfTokens) <= premiumMaxSupply, "Premium mint would exceed max supply");

        require(mintPrice.div(2).mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
        require(premiumPurchased[msg.sender] <= premiumMaxApeMintPerOneAddress, "you can't mint more than maxPerOne");

        if (presaleStarted) {
            require(whitelisted[msg.sender] == true, "you are not whitelisted for the presale");
        }

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply();
            if (premiumMinted < premiumMaxSupply) {
                premiumMinted += 1;
                premiumPurchased[msg.sender] += 1;
                _updateAndMint(msg.sender, mintIndex);
            }
        }
    }

    function isEligableForPremium(address _user) public view returns (bool) {
        if (
            IERC721(bayc).balanceOf(_user) != 0 ||
            IERC721(coolcats).balanceOf(_user) != 0 ||
            IERC721(dogePound).balanceOf(_user) != 0 ||
            IERC721(mekaverse).balanceOf(_user) != 0
        ) return true;

        return false;
    }

    function reserveApes(address _to, uint256 _numberOfTokens) external onlyOwner {
        require(_to != address(0), "Invalid address");

        uint256 supply = totalSupply();

        for (uint256 i = 0; i < _numberOfTokens; i++) {
            normalMinted += 1;
            _updateAndMint(_to, supply + i);
        }
    }

    function _updateAndMint(address _to, uint256 _tokenId) internal {
        _safeMint(_to, _tokenId);
        if (proxy != address(0)) IYieldProxy(proxy).updateRewardonMint(_to, _tokenId);
    }

    function setYieldProxy(address _proxy) external onlyOwner {
        proxy = _proxy;
    }

    function withdraw(address to) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(to).transfer(balance);
    }

    function withdrawSome(address to, uint256 amount) external onlyOwner {
        payable(to).transfer(amount);
    }

    function removeMinter(address account) external onlyOwner {
        _removeMinter(account);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        if (proxy != address(0)) {
            IYieldProxy(proxy).updateReward(from, to, tokenId);
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
