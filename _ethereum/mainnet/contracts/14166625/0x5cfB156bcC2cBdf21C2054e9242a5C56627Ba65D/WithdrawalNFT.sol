// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./ERC721.sol";
import "./Ownable.sol";
import "./Data.sol";

/**
 * @title WithdrawalNFT
 * @dev Implementation of WithdrawalNFT "The Withdrawal Proof"
 */

contract WithdrawalNFT is ERC721, Ownable {

    // Proxy "alphaStrategy contract
    address proxy;  

    // Users Withdrawal data 
    struct PendingWithdrawal {
        Data.State state;
        uint256 amountAlpha;
        uint256 listPointer;
    }
    mapping(address => PendingWithdrawal) public pendingWithdrawPerAddress;
    address[] public usersOnPendingWithdraw;

    // NFT mapping 
    mapping(address => uint256) private tokenIdPerAddress;

    constructor () ERC721 ("Alpha Withdraw", "Alpha_W"){
     }

    // Modifiers
    modifier onlyProxy() {
        require(
            proxy != address(0),
            "Formation.Fi: proxy is the zero address"
        );
        require(msg.sender == proxy, "Formation.Fi: Caller is not the proxy");
         _;
    }

    // Getter functions
    function getTokenId(address _owner) public view returns (uint256) {
        return tokenIdPerAddress[ _owner];
    }
     function getUsersSize() public view returns (uint256) {
        return usersOnPendingWithdraw.length;
    }
    function getUsers() public view returns (address[] memory) {
        return usersOnPendingWithdraw;
    }

    // Setter functions
    function setProxy(address _proxy) public onlyOwner {
        require(
            _proxy != address(0),
            "Formation.Fi: proxy is the zero address"
        );
        proxy = _proxy;
    }    

    // Functions "mint" and "burn"
    function mint(address _account, uint256 _tokenId, uint256 _amount) 
       external onlyProxy {
       require (balanceOf( _account) == 0, "Formation.Fi: account has already a withdraw NFT");
       _safeMint(_account,  _tokenId);
       tokenIdPerAddress[_account] = _tokenId;
       updateWithdrawData (_account,  _tokenId,  _amount, true);
    }

    function burn(uint256 tokenId) internal {
        address owner = ownerOf(tokenId);
        require (pendingWithdrawPerAddress[owner].state != Data.State.PENDING, 
        "Formation.Fi: position is on pending");
        deleteWithdrawData(owner);
        _burn(tokenId);   
    }

    // Update user withdraw data
    function updateWithdrawData (address _account, uint256 _tokenId, 
        uint256 _amount, bool add) public onlyProxy {
        require (_exists(_tokenId), "Formation Fi: token does not exist");
        require (ownerOf(_tokenId) == _account , 
         "Formation.Fi: account is not the token owner");
        if( _amount > 0){
            if (add){
               pendingWithdrawPerAddress[_account].state = Data.State.PENDING;
               pendingWithdrawPerAddress[_account].amountAlpha = _amount;
               pendingWithdrawPerAddress[_account].listPointer = usersOnPendingWithdraw.length;
               usersOnPendingWithdraw.push(_account);
            }
            else {
               require(pendingWithdrawPerAddress[_account].amountAlpha >= _amount, 
               "Formation.Fi: amount excedes pending withdraw");
               uint256 _newAmount = pendingWithdrawPerAddress[_account].amountAlpha - _amount;
               pendingWithdrawPerAddress[_account].amountAlpha = _newAmount;
               if (_newAmount == 0){
                   pendingWithdrawPerAddress[_account].state = Data.State.NONE;
                   burn(_tokenId);
                }
            }     
       }
    }

    // Delete user withdraw data 
    function deleteWithdrawData(address _account) internal {
        require(
          _account!= address(0),
          "Formation.Fi: account is the zero address"
        );
        uint256 _ind = pendingWithdrawPerAddress[_account].listPointer;
        address _user = usersOnPendingWithdraw[usersOnPendingWithdraw.length -1];
        usersOnPendingWithdraw[ _ind] = _user ;
        pendingWithdrawPerAddress[ _user].listPointer = _ind;
        usersOnPendingWithdraw.pop();
        delete pendingWithdrawPerAddress[_account]; 
        delete tokenIdPerAddress[_account];    
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
       if ((to != address(0)) && (from != address(0))){
          require ((to != proxy), 
           "Formation Fi: destination address is the proxy"
          );
          uint256 indFrom = pendingWithdrawPerAddress[from].listPointer;
          pendingWithdrawPerAddress[to] = pendingWithdrawPerAddress[from];
          pendingWithdrawPerAddress[from].state = Data.State.NONE;
          pendingWithdrawPerAddress[from].amountAlpha =0;
          usersOnPendingWithdraw[indFrom] = to; 
          tokenIdPerAddress[to] = tokenIdPerAddress[from];
          delete pendingWithdrawPerAddress[from];
          delete tokenIdPerAddress[from];
        }
    }
   
}
  