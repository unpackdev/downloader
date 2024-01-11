// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./ERC721.sol";
import "./Ownable.sol";
import "./Data.sol";


/** 
* @author Formation.Fi.
* @notice The Implementation of the user's deposit proof token {ERC721}.
*/

contract DepositConfirmation is ERC721, Ownable {
    struct PendingDeposit {
        Data.State state;
        uint256 amount;
        uint256 listPointer;
    }
    uint256 public tolerance = 1e3; 
    address public proxyInvestement;
    string public baseURI;
    mapping(address => uint256) private tokenIdPerAddress;
    mapping(address => PendingDeposit) public pendingDepositPerAddress;
    address[] public usersOnPendingDeposit;
    event MintDeposit(address indexed _address, uint256 _id);
    event BurnDeposit(address indexed _address, uint256 _id);
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
        require(
           _account!= address(0),
            "Formation.Fi: zero address"
        );

        return tokenIdPerAddress[_account];
    }

     /**
     * @dev get the number of users.
     * @return number of users.
     */
    function getUsersSize() external view  returns (uint256) {
        return usersOnPendingDeposit.length;
    }
    
     /**
     * @dev get addresses of users on deposit pending.
     * @return  addresses of users.
     */
    function getUsers() external view returns (address[] memory) {
        return usersOnPendingDeposit;
    }

     /**
     * @dev update the proxy.
     * @param _proxyInvestement the new proxy.
     */
    function setProxy(address _proxyInvestement) external onlyOwner {
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
     * @dev mint the deposit proof ERC721 token.
     * @notice the user receives this token when he makes 
     * a deposit request.
     * Each user's address can at most have one deposit proof token.
     * @param _account The user's address.
     * @param _tokenId The id of the token.
     * @param _amount The deposit amount in the requested Stablecoin.
     * @notice Emits a {MintDeposit} event with `_account` and `_tokenId `.
     */
    function mint(address _account, uint256 _tokenId, uint256 _amount) 
       external onlyProxy {
       require (balanceOf(_account) == 0, "Formation.Fi: has deposit token");
       _safeMint(_account,  _tokenId);
       updateDepositData( _account,  _tokenId, _amount, true);
       emit MintDeposit(_account, _tokenId);
    }

     /**
     * @dev burn the deposit proof ERC721 token.
     * @notice the token is burned  when the manager fully validates
     * the user's deposit request.
     * @param _tokenId The id of the token.
     * @notice Emits a {BurnDeposit} event with `owner` and `_tokenId `.
     */
    function burn(uint256 _tokenId) internal {
        address owner = ownerOf(_tokenId);
        require (pendingDepositPerAddress[owner].state != Data.State.PENDING,
        "Formation.Fi: is on pending");
        _deleteDepositData(owner);
        _burn(_tokenId); 
        emit BurnDeposit(owner, _tokenId);
    }
     
     /**
     * @dev update the user's deposit data.
     * @notice this function is called after each desposit request 
     * by the user or after each validation by the manager.
     * @param _account The user's address.
     * @param _tokenId The depoist proof token id.
     * @param _amount  The deposit amount to be added or removed.
     * @param isAddCase  = 1 when teh user makes a deposit request.
     * = 0, when the manager validates the user's deposit request.
     */
    function updateDepositData(address _account, uint256 _tokenId, 
        uint256 _amount, bool isAddCase) public onlyProxy {
        require (_exists(_tokenId), "Formation.Fi: no token");
        require (ownerOf(_tokenId) == _account , "Formation.Fi:  not owner");
        if( _amount > 0){
           if (isAddCase){
              if(pendingDepositPerAddress[_account].amount == 0){
                  pendingDepositPerAddress[_account].state = Data.State.PENDING;
                  pendingDepositPerAddress[_account].listPointer = usersOnPendingDeposit.length;
                  tokenIdPerAddress[_account] = _tokenId;
                  usersOnPendingDeposit.push(_account);
                }
                pendingDepositPerAddress[_account].amount +=  _amount;
            }
            else {
               require(pendingDepositPerAddress[_account].amount >= _amount, 
               "Formation Fi: not enough amount");
               uint256 _newAmount = pendingDepositPerAddress[_account].amount - _amount;
               pendingDepositPerAddress[_account].amount = _newAmount;
               if (_newAmount <= tolerance){
                  pendingDepositPerAddress[_account].state = Data.State.NONE;
                  burn(_tokenId);
                }
            }
        }
    }    

    
     /**
     * @dev delete the user's deposit proof token data.
     * @notice this function is called when the user's deposit request is fully 
     * validated by the manager.
     * @param _account The user's address.
     */
    function _deleteDepositData(address _account) internal {
        require(
           _account!= address(0),
            "Formation.Fi: zero address"
        );

         uint256 _index = pendingDepositPerAddress[_account].listPointer;
         address _lastUser = usersOnPendingDeposit[usersOnPendingDeposit.length - 1];
         usersOnPendingDeposit[_index] = _lastUser;
         pendingDepositPerAddress[_lastUser].listPointer = _index;
         usersOnPendingDeposit.pop();
         delete pendingDepositPerAddress[_account]; 
         delete tokenIdPerAddress[_account];    
    }

     /**
     * @dev update the deposit token proof data of both the sender and the receiver 
       when the token is transferred.
     * @param from The sender's address.
     * @param to The receiver's address.
     * @param tokenId The deposit token proof id.
     */
    function _beforeTokenTransfer(
       address from,
       address to,
       uint256 tokenId
    )   internal virtual override {
        if ((to != address(0)) && (from != address(0))){
            uint256 indexFrom = pendingDepositPerAddress[from].listPointer;
            pendingDepositPerAddress[to] = pendingDepositPerAddress[from];
            pendingDepositPerAddress[from].state = Data.State.NONE;
            pendingDepositPerAddress[from].amount = 0;
            usersOnPendingDeposit[indexFrom] = to; 
            tokenIdPerAddress[to] = tokenId;
            delete pendingDepositPerAddress[from];
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
  