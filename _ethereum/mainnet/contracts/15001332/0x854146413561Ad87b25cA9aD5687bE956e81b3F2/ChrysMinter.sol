// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./Strings.sol";
import "./PaperVerification.sol";
import "./SignedAllowance.sol";

interface INFT { 
    function mint(address to, uint256 qty) external; 
    function unclaimedSupply() external view returns (uint256);
}

contract NFTminter is Ownable, PaperVerification, SignedAllowance{  

using Strings for uint256;

    /*///////////////////////////////////////////////////////////////
                            GENERAL STORAGE
    //////////////////////////////////////////////////////////////*/

    INFT nftContract;
    uint256 public presalePrice = 250000000000000000; // 0.25 eth
    uint256 public publicSalePrice = 250000000000000000; // 0.25 eth
    bool public publicSaleActive;
    bool public presaleActive;
    uint256 public maxPerMint;

    address public artistAddress;
    uint256 private _totalShares;
    address[] private _payees;
    mapping(address => uint256) private _shares;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _nftContract, address _paperKey) PaperVerification(_paperKey) {
        setNFTContract(_nftContract);      
    }

    /*///////////////////////////////////////////////////////////////
                        MINTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function paperMint(
            PaperMintData.MintData calldata _mintData,
            bytes calldata _data
        ) external payable onlyPaper(_mintData) {
            require (msg.value >= price() * _mintData.quantity, "Minter: Not Enough Eth");
            nftContract.mint(_mintData.recipient, _mintData.quantity);
    }

    function presaleOrder(address to, uint256 nonce, bytes memory signature) public payable {
        require (presaleActive, "Presale not active");

        //_mintQty is stored in the right-most 128 bits of the nonce
        uint256 qty = uint256(uint128(nonce));

        require (msg.value >= presalePrice * qty, "Minter: Not Enough Eth");
        
        // this will throw if the allowance has already been used or is not valid
        _useAllowance(to, nonce, signature);

        nftContract.mint(to, qty); 
    }
    
    function publicOrder(address to, uint256 qty) public payable {
        require (publicSaleActive, "Public sale not active");
        require (qty <= maxPerMint, ">Max per mint");
        require (msg.value >= publicSalePrice * qty, "Minter: Not Enough Eth");
        nftContract.mint(to, qty); 
    }

    function adminMint(address to, uint256 qty) public onlyOwner {
        nftContract.mint(to, qty);
    }

    /*///////////////////////////////////////////////////////////////
                        VIEWS
    //////////////////////////////////////////////////////////////*/

    function price() public view returns (uint256) {
        if (publicSaleActive) {
            return publicSalePrice;
        } else {
            return presalePrice;
        } 
    }

    function getClaimIneligibilityReason(address userWallet, uint256 quantity) public pure returns (string memory) {
        return "";
    }

    function unclaimedSupply() public view returns (uint256) {
        return nftContract.unclaimedSupply();
    }

    /*///////////////////////////////////////////////////////////////
                       ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function setNFTContract(address _newNFT) public onlyOwner {
        nftContract = INFT(_newNFT);
    }

    function setPresalePrice(uint256 _newPresalePrice) public onlyOwner {
        presalePrice = _newPresalePrice;
    }

    function setPublicSalePrice(uint256 _newPublicSalePrice) public onlyOwner {
        publicSalePrice = _newPublicSalePrice;
    }

    function switchPublicSale() public onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

    function switchPresale() public onlyOwner {
        presaleActive = !presaleActive;
    }

    /// @notice sets allowance signer, this can be used to revoke all unused allowances already out there
    /// @param newSigner the new signer
    function setAllowancesSigner(address newSigner) external onlyOwner {
        _setAllowancesSigner(newSigner);
    }

    //set Artist
    function setArtist(address _newArtistAddress) public onlyOwner {
        require(_newArtistAddress != address(0), "Artist account is the zero address");
        artistAddress = _newArtistAddress; 
    }

    function setMaxPerMint(uint256 _newMaxPerMint) public onlyOwner {
        maxPerMint = _newMaxPerMint;
    }

    function setPaperKey(address _paperKey) public onlyOwner {
        _setPaperKey(_paperKey);
    }

    /*///////////////////////////////////////////////////////////////
                       WITHDRAWALS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Add a new payee to the contract or change shares for the existing one.
     * @param account The address of the payee to add.
     * @param accShare The number of shares owned by the payee.
     */
    function _setPayee(address account, uint256 accShare) public onlyOwner {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(accShare > 0, "PaymentSplitter: shares are 0");

        if (_shares[account] == 0) {
            _payees.push(account);
        }    
        _shares[account] = accShare;
        updateShares();
    }

    function updateShares() internal {
        _totalShares = 0;
        for (uint i = 0; i < _payees.length; i++) {
            _totalShares = _totalShares + _shares[_payees[i]];
        }
    }

    //withdraw!
    function withdraw(uint256 amount) public {
        require(owner() == _msgSender() || artistAddress == _msgSender(), "!artist or owner");
        require(_totalShares != 0, "nobody to withdraw to");
        for (uint256 i=0; i<_payees.length ; i++) {
            address payee = _payees[i];
            uint256 payment = amount * _shares[payee] / _totalShares;
            payable(payee).transfer(payment);
        }
    }

    /*///////////////////////////////////////////////////////////////
                       ERC721Receiver interface compatibility
    //////////////////////////////////////////////////////////////*/

    function onERC721Received(
    address, 
    address, 
    uint256, 
    bytes calldata
    ) external pure returns(bytes4) {
        return bytes4(keccak256("I do not receive ERC721"));
    } 
}

//   That's all, folks!


