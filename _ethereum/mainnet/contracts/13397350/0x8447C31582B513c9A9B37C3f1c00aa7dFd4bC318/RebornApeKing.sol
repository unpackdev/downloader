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
    uint256 public premiumMintPrice;

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

    mapping(address => bool) whitelisted;

    mapping(address => uint256) premiumPurchased;

    address public dogePound = 0xF4ee95274741437636e748DdAc70818B4ED7d043;
    address public bayc = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;
    address public coolcats = 0x1A92f7381B9F03921564a437210bB9396471050C;
    address public cryptoPunk = 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;
    address public crypToadz = 0x1CB1A5e65610AEFF2551A50f76a87a7d3fB649C6;

    string private _uri;

    constructor(string memory uri_) ERC721("The Reborn Ape King", "RAK") {
        mintPrice = 80000000000000000;
        premiumMintPrice = 40000000000000000;
        maxApePurchase = 20;
        premiumMaxApePurchase = 10;

        normalMaxSupply = 11000;
        premiumMaxSupply = 1000;
        premiumMaxApeMintPerOneAddress = 30;

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

    function setPremiumMintPrice(uint256 _price) external onlyOwner {
        premiumMintPrice = _price;
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

    function setStopPremiumsale(bool _stop) external onlyOwner {
        stopPremiumsale = _stop;
    }

    ///@dev Set maxsupply
    function setNormalMaxSupply(uint256 _max) external onlyOwner {
        normalMaxSupply = _max;
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

    ///@dev mint ape kings
    function mintApeKing(uint256 numberOfTokens) external payable {
        require(publicSaleStarted || presaleStarted, "Sale must be active to mint");

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
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    ///@dev mint premium ape kings
    function mintApeKingPremium(uint256 numberOfTokens) external payable {
        require(stopPremiumsale == false, "Premium sale is stopped");
        require(isEligableForPremium(msg.sender) == true, "you are not eligable for premium mint");

        require(publicSaleStarted || presaleStarted, "Sale must be active to mint");

        require(numberOfTokens <= premiumMaxApePurchase, "Invalid amount to mint per once");
        require(premiumMinted.add(numberOfTokens) <= premiumMaxSupply, "Premium mint would exceed max supply");
        require(premiumMintPrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");

        require(premiumPurchased[msg.sender] <= premiumMaxApeMintPerOneAddress, "you can't mint more than maxPerOne");

        if (presaleStarted) {
            require(whitelisted[msg.sender] == true, "you are not whitelisted for the presale");
        }

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply();
            if (premiumMinted < premiumMaxSupply) {
                premiumMinted += 1;
                premiumPurchased[msg.sender] += 1;
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function isEligableForPremium(address _user) public view returns (bool) {
        if (
            IERC721(bayc).balanceOf(_user) > 1 ||
            IERC721(cryptoPunk).balanceOf(_user) > 0 ||
            IERC721(coolcats).balanceOf(_user) > 4 ||
            IERC721(dogePound).balanceOf(_user) > 6 ||
            IERC721(crypToadz).balanceOf(_user) > 4
        ) return true;

        return false;
    }

    ///@dev Reserve Ape Kings by owner
    function reserveApes(address _to, uint256 _numberOfTokens) external onlyOwner {
        require(_to != address(0), "Invalid address");

        uint256 supply = totalSupply();

        for (uint256 i = 0; i < _numberOfTokens; i++) {
            normalMinted += 1;
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
