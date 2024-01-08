// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./owned.sol";
import "./StopTheWarOnDrugs.sol";
import "./context.sol";
import "./address-utils.sol";
import "./Initializable.sol";


contract SWDMarketPlace is 
Owned, 
Context, 
Initializable{

    using AddressUtils for address;

    string constant INVALID_ADDRESS = "0501";
    string constant CONTRACT_ADDRESS_NOT_SETUP = "0502";
    string constant NOT_APPROVED= "0503";
    string constant NOT_VALID_NFT = "0504";
    string constant NOT_FOR_SALE = "0505";
    string constant NOT_EHOUGH_ETHER = "0506";
    string constant NEGATIVE_VALUE = "0507";
    string constant NO_CHANGES_INTENDED = "0508";
    string constant NOT_NFT_OWNER = "0509";
    string constant INSUFICIENT_BALANCE = "0510";
    string constant STILL_OWN_NFT_CONTRACT = "0511";
    string constant NFT_ALREADY_MINTED = "0512";
    string constant PRICE_NOT_SET = "0513";
    string constant MINTING_LOCKED = "0514";
    

    event Sent(address indexed payee, uint amount);
    event RoyaltyPaid(address indexed payee, uint amount);
    event SecurityWithdrawal(address indexed payee, uint amount);

    StopTheWarOnDrugs public TokenContract;

    /**
    * @dev Mapping from token ID to its pirce.
    */
    mapping(uint => uint256) internal price;

    /**
    * @dev Mapping from token ID to royalty address.
    */
    mapping(uint => address) internal royaltyAddress;

    /**
    * @dev Mapping from NFT ID to boolean representing
    * if it is for sale or not.
    */
    mapping(uint => bool) internal forSale;

    /**
    * @dev contract balance
    */
    uint internal contractBalance;

    /**
    * @dev reentrancy safe and control for minting method
    */
    bool internal mintLock;


    /**
    * @dev Contract Constructor/Initializer
    */
    function initialize() public initializer { 
        isOwned();
    }

    /**
    * @dev update the address of the NFTs
    * @param nmwdAddress address of NoMoreWarOnDrugs tokens 
    */
    function updateNMWDcontract(address nmwdAddress) external onlyOwner{
        require(nmwdAddress != address(0) && nmwdAddress != address(this),INVALID_ADDRESS);
        require(address(TokenContract) != nmwdAddress,NO_CHANGES_INTENDED);
        TokenContract = StopTheWarOnDrugs(nmwdAddress);
    }

    /**
    * @dev transfers ownership of the NFT contract to the owner of 
    * the marketplace contract. Only if the marketplace owns the NFT
    */
    function getBackOwnership() external onlyOwner{
        require(address(TokenContract) != address(0),CONTRACT_ADDRESS_NOT_SETUP);
        TokenContract.transferOwnership(address(owner));
    }


    /**
    * @dev Purchase _tokenId
    * @param _tokenId uint token ID (painting number)
    */
    function purchaseToken(uint _tokenId) external payable  {
        require(forSale[_tokenId], NOT_FOR_SALE);
        require(_msgSender() != address(0) && _msgSender() != address(this));
        require(price[_tokenId] > 0,PRICE_NOT_SET);
        require(msg.value >= price[_tokenId]);
        require(TokenContract.ownerOf(_tokenId) != address(0), NOT_VALID_NFT);

        address tokenSeller = TokenContract.ownerOf(_tokenId);
        require(TokenContract.getApproved(_tokenId) == address(this) || 
                TokenContract.isApprovedForAll(tokenSeller, address(this)), 
                NOT_APPROVED);

        forSale[_tokenId] = false;


        // this is the fee of the contract per transaction: 0.8%
        uint256 saleFee = (msg.value / 1000) * 8;
        contractBalance += saleFee;

        //calculating the net amount of the sale
        uint netAmount = msg.value - saleFee;

        (address royaltyReceiver, uint256 royaltyAmount) = TokenContract.royaltyInfo( _tokenId, netAmount);

        //calculating the amount to pay the seller 
        uint256 toPaySeller = netAmount - royaltyAmount;

        //paying the seller and the royalty recepient
        (bool successSeller, ) =tokenSeller.call{value: toPaySeller, gas: 120000}("");
        require( successSeller, "Paying seller failed");
        (bool successRoyalties, ) =royaltyReceiver.call{value: royaltyAmount, gas: 120000}("");
        require( successRoyalties, "Paying Royalties failed");

        //transfer the NFT to the buyer
        TokenContract.safeTransferFrom(tokenSeller, _msgSender(), _tokenId);

        //notifying the blockchain
        emit Sent(tokenSeller, toPaySeller);
        emit RoyaltyPaid(royaltyReceiver, royaltyAmount);
        
    }

    /**
    * @dev mint an NFT through the market place
    * @param _to the address that will receive the freshly minted NFT
    * @param _tokenId uint token ID (painting number)
    */
    function mintThroughPurchase(address _to, uint _tokenId) external payable {
        require(price[_tokenId] > 0, PRICE_NOT_SET);
        require(msg.value >= price[_tokenId],NOT_EHOUGH_ETHER);
        require(_msgSender() != address(0) && _msgSender() != address(this));
        //avoid reentrancy. Also mintLocked before launch time.
        require(!mintLock,MINTING_LOCKED);
        mintLock=true;

        //we extract the royalty address from the mapping
        address royaltyRecipient = royaltyAddress[_tokenId];
        //this is hardcoded 6.0% for all NFTs
        uint royaltyValue = 600;

        contractBalance += msg.value;

        TokenContract.mint(_to, _tokenId, royaltyRecipient, royaltyValue);
        
        mintLock=false;
    }

    /**
    * @dev send / withdraw _amount to _payee
    * @param _payee the address where the funds are going to go
    * @param _amount the amount of Ether that will be sent
    */
    function withdrawFromContract(address _payee, uint _amount) external onlyOwner {
        require(_payee != address(0) && _payee != address(this));
        require(contractBalance >= _amount, INSUFICIENT_BALANCE);
        require(_amount > 0 && _amount <= address(this).balance, NOT_EHOUGH_ETHER);

        //we check if somebody has hacked the contract, in which case we send all the funds to 
        //the owner of the contract
        if(contractBalance != address(this).balance){
            contractBalance = 0;
            payable(owner).transfer(address(this).balance);
            emit SecurityWithdrawal(owner, _amount);
        }else{
            contractBalance -= _amount;
            payable(_payee).transfer(_amount);
            emit Sent(_payee, _amount);
        }
    }   

    /**
    * @dev Updates price for the _tokenId NFT
    * @dev Throws if updating price to the same current price, or to negative
    * value, or is not the owner of the NFT.
    * @param _price the price in wei for the NFT
    * @param _tokenId uint token ID (painting number)
    */
    function setPrice(uint _price, uint _tokenId) external {
        require(_price > 0, NEGATIVE_VALUE);
        require(_price != price[_tokenId], NO_CHANGES_INTENDED);
        //Only owner of NFT can set a price
        address _address = TokenContract.ownerOf(_tokenId);
        require(_address == _msgSender());
        
        //finally, we do what we came here for.
        price[_tokenId] = _price;
    } 

    /**
    * @dev Updates price for the _tokenId NFT before minting
    * @dev Throws if updating price to the same current price, or to negative
    * value, or if sender is not the owner of the marketplace.
    * @param _price the price in wei for the NFT
    * @param _tokenId uint token ID (painting number)
    * @param _royaltyAddress the address that will receive the royalties.
    */
    function setPriceForMinting(uint _price, uint _tokenId, address _royaltyAddress) external onlyOwner{
        require(_price > 0, NEGATIVE_VALUE);
        require(_price != price[_tokenId], NO_CHANGES_INTENDED);
        require(_royaltyAddress != address(0) && _royaltyAddress != address(this),INVALID_ADDRESS);
        //this makes sure this is only set before minting. It is impossible to change the
        //royalty address once it's been minted. The price can then be only reset by the NFT owner.
        require( !TokenContract.exists(_tokenId),NFT_ALREADY_MINTED);
        
        //finally, we do what we came here for.
        price[_tokenId] = _price;
        royaltyAddress[_tokenId] = _royaltyAddress;
    } 

    /**
    * @dev get _tokenId price in wei
    * @param _tokenId uint token ID 
    */
    function getPrice(uint _tokenId) external view returns (uint256){
        return price[_tokenId];
    }    

    /**
    * @dev get marketplace's balance (weis)
    */
    function getMarketPlaceBalance() external view returns (uint256){
        return contractBalance;
    }   

    /**
    * @dev sets the token with _tokenId a boolean representing if it's for sale or not.
    * @param _tokenId uint token ID 
    * @param _forSale is it or not for sale? (true/false)
    */
    function setForSale(uint _tokenId, bool _forSale) external returns (bool){
        
        try TokenContract.ownerOf(_tokenId) returns (address _address) {
            require(_address == _msgSender(),NOT_NFT_OWNER);
        }catch {
           return false;
        }
        require(_forSale != forSale[_tokenId],NO_CHANGES_INTENDED);
        forSale[_tokenId] = _forSale;
        return true;
    } 

    /**
    * @dev gets the token with _tokenId forSale variable.
    * @param _tokenId uint token ID 
    */
    function getForSale(uint _tokenId) external view returns (bool){
        return forSale[_tokenId];
    } 

    /**
   * @dev Burns an NFT.
   * @param _tokenId of the NFT to burn.
   */
    function burn(uint256 _tokenId ) external onlyOwner {
        TokenContract.burn( _tokenId);
  }
    /**
   * @dev the receive method to avoid balance incongruence
   */
  receive() external payable{
        contractBalance += msg.value;
    }

  /**
   * @dev locks/unlocks the mint method.
   * @param _locked bool value to set.
   */
    function setMintLock(bool _locked) external onlyOwner {
        mintLock=_locked;
  }


}