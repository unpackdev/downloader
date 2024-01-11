// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Ownable.sol";
import "./ERC721.sol";
import "./Data.sol";

/** 
* @author Formation.Fi.
* @notice The Implementation of the user's withdrawal proof token {ERC721}.
*/

contract WithdrawalConfirmation is ERC721, Ownable { 
    struct PendingWithdrawal {
        Data.State state;
        uint256 amount;
        uint256 listPointer;
    }
    uint256 public tolerance = 1e3;
    address public proxyInvestement; 
    string public baseURI;
    mapping(address => uint256) private tokenIdPerAddress;
    mapping(address => PendingWithdrawal) public pendingWithdrawPerAddress;
    address[] public usersOnPendingWithdraw;
    event MintWithdrawal(address indexed _address, uint256 _id);
    event BurnWithdrawal(address indexed _address, uint256 _id);
    event UpdateBaseURI( string _baseURI);

    constructor(string memory _name , string memory _symbol)  
    ERC721 ("_name",  "_symbol"){
    }

    modifier onlyProxy() {
        require(
            proxyInvestement != address(0),
            "Formation.Fi: zero address"
        );

        require(msg.sender == proxyInvestement, "Formation.Fi: not the proxy");
         _;
    }

     /**
     * @dev get the token id of user's address.
     * @param _account The user's address.
     * @return token id.
     */
    function getTokenId(address _account) external view returns (uint256) {
        return tokenIdPerAddress[ _account];
    }

      /**
     * @dev get the number of users.
     * @return number of users.
     */
     function getUsersSize() external view returns (uint256) {
        return usersOnPendingWithdraw.length;
    }

    /**
     * @dev get addresses of users on withdrawal pending.
     * @return  addresses of users.
     */
    function getUsers() public view returns (address[] memory) {
        return usersOnPendingWithdraw;
    }

    /**
     * @dev update the proxy.
     * @param _proxyInvestement the new proxy.
     */
    function setProxy(address _proxyInvestement) public onlyOwner {
        require(
            _proxyInvestement != address(0),
            "Formation.Fi: zero address"
        );

        proxyInvestement = _proxyInvestement;
    }    

    /**
     * @dev update the Metadata URI
     * @param _tokenURI the Metadata URI.
     */
    function setBaseURI(string calldata _tokenURI) external onlyOwner {
        baseURI = _tokenURI;
        emit UpdateBaseURI(_tokenURI);
    }
    
    /**
     * @dev mint the withdrawal proof ERC721 token.
     * @notice the user receives this token when he makes 
     * a withdrawal request.
     * Each user's address can at most have one withdrawal proof token.
     * @param _account The user's address.
     * @param _tokenId The id of the token.
     * @param _amount The withdrawal amount in the product token.
     * @notice Emits a {MintWithdrawal} event with `_account` and `_tokenId `.
     */
    function mint(address _account, uint256 _tokenId, uint256 _amount) 
       external onlyProxy {
       require (balanceOf( _account) == 0, "Formation.Fi:  has withdrawal token");
       _safeMint(_account,  _tokenId);
       tokenIdPerAddress[_account] = _tokenId;
       updateWithdrawalData (_account,  _tokenId,  _amount, true);
       emit MintWithdrawal(_account, _tokenId);
    }

     /**
     * @dev burn the withdrawal proof ERC721 token.
     * @notice the token is burned  when the manager fully validates
     * the user's withdrawal request.
     * @param _tokenId The id of the token.
     * @notice Emits a {BurnWithdrawal} event with `owner` and `_tokenId `.
     */
    function burn(uint256 _tokenId) internal {
        address owner = ownerOf(_tokenId);
        require (pendingWithdrawPerAddress[owner].state != Data.State.PENDING, 
        "Formation.Fi: is on pending");
        _deleteWithdrawalData(owner);
        _burn(_tokenId);   
        emit BurnWithdrawal(owner, _tokenId);
    }

    /**
     * @dev update the user's withdrawal data.
     * @notice this function is called after the withdrawal request 
     * by the user or after each validation by the manager.
     * @param _account The user's address.
     * @param _tokenId The withdrawal proof token id.
     * @param _amount  The withdrawal amount to be added or removed.
     * @param isAddCase  = 1 when teh user makes a withdrawal request.
     * = 0, when the manager validates the user's withdrawal request.
     */
    function updateWithdrawalData (address _account, uint256 _tokenId, 
        uint256 _amount, bool isAddCase) public onlyProxy {

        require (_exists(_tokenId), "Formation Fi: no token");

        require (ownerOf(_tokenId) == _account , 
         "Formation.Fi: not owner");

        if( _amount > 0){
            if (isAddCase){
               pendingWithdrawPerAddress[_account].state = Data.State.PENDING;
               pendingWithdrawPerAddress[_account].amount = _amount;
               pendingWithdrawPerAddress[_account].listPointer = usersOnPendingWithdraw.length;
               usersOnPendingWithdraw.push(_account);
            }
            else {
               require(pendingWithdrawPerAddress[_account].amount >= _amount, 
               "Formation.Fi: not enough amount");
               uint256 _newAmount = pendingWithdrawPerAddress[_account].amount - _amount;
               pendingWithdrawPerAddress[_account].amount = _newAmount;
               if (_newAmount <= tolerance){
                   pendingWithdrawPerAddress[_account].state = Data.State.NONE;
                   burn(_tokenId);
                }
            }     
       }
    }

    /**
     * @dev delete the user's withdrawal proof token data.
     * @notice this function is called when the user's withdrawal request is fully 
     * validated by the manager.
     * @param _account The user's address.
     */
    function _deleteWithdrawalData(address _account) internal {
        require(
          _account!= address(0),
          "Formation.Fi: zero address"
        );
        uint256 _index = pendingWithdrawPerAddress[_account].listPointer;
        address _lastUser = usersOnPendingWithdraw[usersOnPendingWithdraw.length -1];
        usersOnPendingWithdraw[_index] = _lastUser ;
        pendingWithdrawPerAddress[_lastUser].listPointer = _index;
        usersOnPendingWithdraw.pop();
        delete pendingWithdrawPerAddress[_account]; 
        delete tokenIdPerAddress[_account];    
    }

     /**
     * @dev update the withdrawal token proof data of both the sender and the receiver 
       when the token is transferred.
     * @param from The sender's address.
     * @param to The receiver's address.
     * @param tokenId The withdrawal token proof id.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
       if ((to != address(0)) && (from != address(0))){
          uint256 indexFrom = pendingWithdrawPerAddress[from].listPointer;
          pendingWithdrawPerAddress[to] = pendingWithdrawPerAddress[from];
          pendingWithdrawPerAddress[from].state = Data.State.NONE;
          pendingWithdrawPerAddress[from].amount =0;
          usersOnPendingWithdraw[indexFrom] = to; 
          tokenIdPerAddress[to] = tokenId;
          delete pendingWithdrawPerAddress[from];
          delete tokenIdPerAddress[from];
        }
    }
    
    /**
     * @dev Get the Metadata URI
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
   
}
  