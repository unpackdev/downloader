// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";

contract eChibi is ERC721A, Ownable {
    bool private _locked;
    bool public SaleIsActive;
    uint8 public constant MaxPerTransaction = 10;
    uint16 public constant MaxTokens = 10000;

    address private _verificationWallet;

    uint256 public WhitelistPrice = 0.02 ether;
    uint256 public TokenPrice = 0.04 ether;

    string private _baseTokenURI;

    mapping(address => bool) public ClaimedWhitelist;
    
    constructor(address verifier) ERC721A("eChibi", "chib", MaxPerTransaction, MaxTokens) {
        _verificationWallet = verifier;
    }

    function withdraw() external onlyOwner {
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success);
    }

    // mints
    function reserve(uint256 count) public onlyOwner {
        require(totalSupply() + count <= MaxTokens, "Supply overflow");
        _safeMint(_msgSender(), count, false, "");
    }

    // mint and transfer the nfts to the original holders
    function airdropGenesisChibis(address[] calldata addresses, uint256[] calldata amounts) external onlyOwner {
        require(addresses.length == amounts.length, "Invalid inputs");

        uint256 totalMints = 0;
        uint256 initialSupply = totalSupply();
        for(uint i = 0; i < amounts.length; i++) {
            totalMints += amounts[i];
        }

        reserve(totalMints);
        setApprovalForAll(address(this), true);

        for(uint i = 0; i < addresses.length; i++) {
            for(uint j = 0; j < amounts[i]; j++) {
                transferFrom(_msgSender(), addresses[i], initialSupply + j);
            }

            initialSupply += amounts[i];
        }
    }

    function mintWhitelist(bytes calldata signature) external payable botGuard {
        require(SaleIsActive, "Sale must be active in order to mint");
        require(totalSupply() < MaxTokens, "Purchase more than max supply");
        require(msg.value >= WhitelistPrice, "Ether too low");
        require(!ClaimedWhitelist[_msgSender()], "Already claimed");
        require(isValidSignature(signature), "Invalid signature");

        ClaimedWhitelist[_msgSender()] = true;
        _safeMint(_msgSender(), 1);
    }

    function mint(uint256 numTokens) external payable {
        require(SaleIsActive, "Sale must be active in order to mint");
        require(numTokens <= MaxPerTransaction, "Higher than max per transaction");
        require(totalSupply() + numTokens <= MaxTokens, "Purchase more than max supply");
        require(msg.value >= numTokens * TokenPrice, "Ether too low");
        _safeMint(_msgSender(), numTokens);
    }

    // security  
    modifier botGuard() {
        require(!_locked, "locked");
        require(_msgSender() == tx.origin, "no contracts");
        _locked = true;
        _;
        _locked = false;
    }

    function getWalletHash() private view returns (bytes32) {
        return keccak256(abi.encodePacked(_msgSender()));
    }

    function isValidSignature(bytes calldata signature) private view returns (bool) {
        bytes32 combined = ECDSA.toEthSignedMessageHash(getWalletHash());
        address addr = ECDSA.recover(combined, signature);
        return addr == _verificationWallet;
    }

    // getters
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function getTokensOfUser(address user) external view returns (uint256[] memory) {
        uint256 balance = balanceOf(user);
        uint256[] memory tokens = new uint256[](balance);

        for(uint256 i = 0; i < balance; i++) {
            tokens[i] = tokenOfOwnerByIndex(user, i);
        }

        return tokens;
    }

    // setters
    function toggleSaleState() external onlyOwner {
        SaleIsActive = !SaleIsActive;
    }

    function setTokenPrice(uint256 tokenPrice) external onlyOwner {
        TokenPrice = tokenPrice;
    }
    
    function setWhiteListTokenPrice(uint256 tokenPrice) external onlyOwner {
        WhitelistPrice = tokenPrice;
    }
           
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setVerificationWallet(address addr) external onlyOwner {
        _verificationWallet = addr;
    }
}