// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./ERC721.sol";
import "./Ownable.sol";
import "./Data.sol";


/**
 * @title DepositNFT
 * @dev Implementation of DepositNFT "The deposit Proof"
 */

contract DepositNFT is ERC721, Ownable {

    struct PendingDeposit {
        Data.State state;
        uint256 amountStable;
        uint256 listPointer;
    }

    // Proxy "alphaStrategy contract
    address public proxy;
    
    // Users deposit data 
    mapping(address => PendingDeposit) public pendingDepositPerAddress;
    address[] public usersOnPendingDeposit;
    
    

    // NFT mapping 
    mapping(address => uint256) private tokenIdPerAddress;

    constructor ()  ERC721 ("Alpha Deposit ", "ALPHA_D"){
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
    function getTokenId(address _account) public view returns (uint256) {
        require(
           _account!= address(0),
            "Formation.Fi: account is the zero address"
        );
        return tokenIdPerAddress[_account];
    }
    function getUsersSize() public view  returns (uint256) {
        return usersOnPendingDeposit.length;
    }

    function getUsers() public view returns (address[] memory) {
        return usersOnPendingDeposit;
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
       require (balanceOf(_account) == 0, "Formation.Fi: account has already a deposit NFT");
       _safeMint(_account,  _tokenId);
       updateDepositData( _account,  _tokenId, _amount, true);
    }
    function burn(uint256 tokenId) internal {
        address owner = ownerOf(tokenId);
        require (pendingDepositPerAddress[owner].state != Data.State.PENDING,
        "Formation.Fi: position is on pending");
        deleteDepositData(owner);
        _burn(tokenId); 
    }
     
    // Update user deposit data
    function updateDepositData(address _account, uint256 _tokenId, 
        uint256 _amount, bool add) public onlyProxy {
        require (_exists(_tokenId), "Formation.Fi: token does not exist");
        require (ownerOf(_tokenId) == _account , "Formation.Fi: account is not the token owner");
        if( _amount > 0){
           if (add){
              if(pendingDepositPerAddress[_account].amountStable == 0){
                  pendingDepositPerAddress[_account].state = Data.State.PENDING;
                  pendingDepositPerAddress[_account].listPointer = usersOnPendingDeposit.length;
                  tokenIdPerAddress[_account] = _tokenId;
                  usersOnPendingDeposit.push(_account);
                }
              pendingDepositPerAddress[_account].amountStable = pendingDepositPerAddress[_account].amountStable 
              +  _amount;
            }
            else {
               require(pendingDepositPerAddress[_account].amountStable >= _amount, 
               "Formation Fi:  amount excedes pending deposit");
               uint256 _newAmount = pendingDepositPerAddress[_account].amountStable - _amount;
               pendingDepositPerAddress[_account].amountStable = _newAmount;
               if (_newAmount == 0){
                  pendingDepositPerAddress[_account].state = Data.State.NONE;
                  burn(_tokenId);
                }
            }
        }
    }    

    // Delete user deposit data 
    function deleteDepositData(address _account) internal {
        require(
           _account!= address(0),
            "Formation.Fi: account is the zero address"
        );
         uint256 _ind = pendingDepositPerAddress[_account].listPointer;
         address _user = usersOnPendingDeposit[usersOnPendingDeposit.length - 1];
         usersOnPendingDeposit[_ind] = _user;
         pendingDepositPerAddress[_user].listPointer = _ind;
         usersOnPendingDeposit.pop();
         delete pendingDepositPerAddress[_account]; 
         delete tokenIdPerAddress[_account];    
    }

    function _beforeTokenTransfer(
       address from,
       address to,
       uint256 tokenId
    )   internal virtual override {
        if ((to != address(0)) && (from != address(0))){
            require ((to != proxy), 
            "Formation.Fi: destination address cannot be the proxy"
            );
            uint256 indFrom = pendingDepositPerAddress[from].listPointer;
            pendingDepositPerAddress[to] = pendingDepositPerAddress[from];
            pendingDepositPerAddress[from].state = Data.State.NONE;
            pendingDepositPerAddress[from].amountStable =0;
            usersOnPendingDeposit[indFrom] = to; 
            tokenIdPerAddress[to] = tokenIdPerAddress[from];
            delete pendingDepositPerAddress[from];
            delete tokenIdPerAddress[from];
        }
    }
   
}
