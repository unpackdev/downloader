// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./IERC721.sol";
import "./SafeMath.sol";
import "./Address.sol";

contract NFTDAO is IERC20 {

    /// @notice using Openzeppelin contracts for SafeMath and Address
    using SafeMath for uint256;
    using Address for address;

    /// @notice presenting the total supply
    uint256 private _totalSupply;

    /// @notice presenting the amount burned
    uint256 public _burnedSupply;

    /// @notice representing the name of the governance token
    string public _name;

    /// @notice representing the symbol of the governance token
    string public _symbol;

    /// @notice representing the decimals of the governance token
    uint8 public immutable _decimals = 18;

    /// @notice a record of balance of a specific account by address
    mapping(address => uint256) private _balances;

    /// a record of allowances for a specific address by address to address mapping
    mapping(address => mapping(address => uint256)) private _allowances;

    /// presenting the shares for sale
    uint256 public _sharesForSale;

    /// @notice the nft used to create the dao contract
    IERC721 public _nftAddress;

    /// @notice struct for raised nfts
    struct _raisedNftStruct {
        IERC721 nftaddress;
        uint tokenid;
    }

    /// @notice array for raised nfts
    _raisedNftStruct[] public _raisedNftArray;

    /// @notice the token id identifying the nft token
    uint256 public _tokenId;

    /// @notice the owner and creator of the contract
    address public _owner;

    /// @notice the buyout price. once its met, all nfts will be transferred to the buyer, all tokens will be burned
    uint256 public _buyoutPrice;

    /// @notice representing the governance contract of the nft
    address public _governor;

    /// @notice representing the timelock address of the nft for the governor
    address public _timelock;

    /// @notice A record of each accounts delegate
    mapping (address => address) public delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

    /// @notice the buyer address of the dao when sold
    address public BuyerAddress;

    /// init of the contract
    bool public _init;

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /// @notice An event thats emitted when the buyout price is changed
    event BuyoutChanged(uint previousPrice, uint newPrice);

    /// @notice An event thats emitted when the governor has changed
    event GovernorChanged(address oldGovernor, address newGovernor);

    constructor (IERC721 nftAddress_, address owner_, uint256 tokenId_, uint256 totalSupply_, string memory name_, string memory symbol_, uint256 buyoutPrice_) public {
        _nftAddress = nftAddress_;
        _owner = owner_;
        _tokenId = tokenId_;
        _totalSupply = totalSupply_ * 10 ** 18;
        _name = name_;
        _symbol = symbol_;
        _buyoutPrice = buyoutPrice_;
        _sharesForSale = 0;
        _init = false;
        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), owner_, _totalSupply);
    }
    function init(address governorFactory, address timelockFactory, uint256 timelockinit ) public returns (bool) {
        require(msg.sender == _owner, "NFTDAO: only owner");
        _governor = GovernorFactoryInterface(governorFactory).GovernorMint(address(this), _totalSupply);
        _timelock = TimelockFactoryInterface(timelockFactory).TimelockMint(_governor, timelockinit);
        GovernorInstance(_governor).init(_timelock);
        _nftAddress.transferFrom(_owner, address(this), _tokenId);
        _init = true;
        return true;
    }

    /**
    * @dev Destroys `amount` tokens from `account`, reducing
    * and updating burnd tokens for abstraction
    *
    */
    function _burn(uint256 amount) internal {
        _totalSupply -= amount;
    }

    function burnForETH() public {
        uint256 balance = balanceOf(msg.sender);
        _balances[msg.sender] = 0;
        uint256 contractBalalance = address(this).balance;
        uint256 cashout = contractBalalance.mul(balance).div(_totalSupply);
        _burn(balance);
        msg.sender.transfer(cashout);
        emit Transfer(msg.sender, address(0), balance);
    }

    function Buyshares(uint256 amount) public payable {
        require(_sharesForSale >= amount, "NFTDAO: low shares");
        require(msg.value >= amount.mul(_buyoutPrice).div(_totalSupply), "NFTDAO: low amount");

        _balances[msg.sender] += amount;
        _sharesForSale -= amount;

        uint256 cost = msg.value - amount.mul(_buyoutPrice).div(_totalSupply);
        msg.sender.transfer(cost);
    }

    function buyout() public payable {
        require(msg.value >= _buyoutPrice, "NFTDAO: buyout price");

        uint256 balance = _balances[msg.sender];
        _balances[msg.sender] = 0;


        uint256 cost = msg.value - (_buyoutPrice.mul((_totalSupply.sub(balance)).div(_totalSupply)));
        _burn(balance);

        _nftAddress.approve(msg.sender, _tokenId);
        _nftAddress.transferFrom(address(this), msg.sender, _tokenId);
        BuyerAddress = msg.sender;
        msg.sender.transfer(cost);
        emit Transfer(msg.sender, address(0), balance);
    }
    function buyoutTransfer(uint256 min, uint256 max) public {
        require(msg.sender == BuyerAddress, "NFTDAO: only buyer");
        for (uint i=min; i<max; i++) {
            _raisedNftArray[i].nftaddress.approve(msg.sender, _raisedNftArray[i].tokenid);
            _raisedNftArray[i].nftaddress.transferFrom(address(this), msg.sender, _raisedNftArray[i].tokenid);
        }
    }
    function burnSharesForSale(uint256 amount) public returns (bool success) {
        require(msg.sender == _timelock, "NFTDAO: Only Timelock");
        require(msg.sender != address(0), "ERC20: transfer from the zero address");
        require(_sharesForSale >= amount, "NFTDAO: Cant burn more shares");

        _burn(amount);
        _sharesForSale -= amount;

        emit Transfer(msg.sender, address(0), amount);
        return true;
    }

    function _mint(uint256 amount) internal {
        _totalSupply = _totalSupply + amount;
    }

    function mintSharesForSale(uint256 amount) public returns (bool success) {
        require(msg.sender != address(0), "ERC20: transfer from the zero address");
        require(msg.sender == _timelock, "NFTDAO: Only Timelock of the NFT can call mintShares");

        _mint(amount);
        _sharesForSale += amount;

        emit Transfer(address(0), address(this), amount);
        return true;
    }

    function changeBuyoutPrice (uint256 amount) public returns (bool success) {
        require(msg.sender != address(0), "ERC20: transfer from the zero address");
        require(msg.sender == _timelock, "NFTDAO: Only Timelock of the NFT can change buyout price");

        uint256 old_buyout = _buyoutPrice;

        _buyoutPrice = amount;
        emit BuyoutChanged(old_buyout, _buyoutPrice);
        return true;
    }

    function changeGovernor (address newgov) public returns (bool success) {
        require(msg.sender != address(0), "ERC20: transfer from the zero address");
        require(msg.sender == _timelock, "NFTDAO: Only Timelock of the NFT can change govenor");

        address old_gov = _governor;

        _governor = newgov;
        emit GovernorChanged(old_gov, newgov);
        return true;
    }

    function addNft(IERC721 new_nft, uint256 tokenid) public returns (bool success) {
        require(msg.sender == _timelock, "NFTDAO: Only Timelock of the NFT can call add nft");

        _raisedNftStruct memory temp_struct;
        temp_struct.nftaddress = new_nft;
        temp_struct.tokenid = tokenid;

        _raisedNftArray.push(temp_struct);
        return true;
    }

    function returnNft() public returns (bool success) {
        require(msg.sender == _timelock, "NFTDAO: Only Timelock of the NFT can call return nft");

        _nftAddress.approve(_owner, _tokenId);
        _nftAddress.transferFrom(address(this), _owner, _tokenId);
        return true;
    }

    function executeTransaction(address target, uint value, string memory signature, bytes memory data) public payable returns (bytes memory) {
        require(msg.sender == _timelock, "NFTDAO::executeTransaction: from timelock.");

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{value:value}(callData);
        require(success, "NFTDAO::executeTransaction: Transaction execution reverted.");

        return returnData;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
    * @dev See {IERC20-totalSupply}.
    */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev See {IERC20-balanceOf}. Uses burn abstraction for balance updates without gas and universally.
    */
    function balanceOf(address account) public override view returns (uint256) {
        return
        (_balances[account] * _totalSupply) / (_totalSupply - _burnedSupply);
    }

    /**
    * @dev See {IERC20-transfer}.
    *
    * Requirements:
    *
    * - `recipient` cannot be the zero address.
    * - the caller must have a balance of at least `amount`.
    */
    function transfer(address dst, uint256 rawAmount) external override returns (bool) {
        uint256 amount = rawAmount;
        _transferTokens(msg.sender, dst, amount);
        return true;
    }


    /**
    * fallback function for collection funds
    */
    fallback() external payable {

    }

    receive() external payable {

    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
    public
    override
    view
    returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
    public
    override
    returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero ress.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address src, address dst, uint256 rawAmount) external override returns (bool) {
        address spender = msg.sender;
        uint256 spenderAllowance = _allowances[src][spender];
        uint256 amount = rawAmount;

        if (spender != src && spenderAllowance != uint256(-1)) {
            uint256 newAllowance = spenderAllowance.sub(amount, "NFTDAO::transferFrom: transfer amount exceeds spender allowance");
            _allowances[src][spender] = newAllowance;

            //emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }


    /**
 * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
 *
 * This is internal function is equivalent to `approve`, and can be used to
 * e.g. set automatic allowances for certain subsystems, etc.
 *
 * Emits an {Approval} event.
 *
 * Requirements:
 *
 * - `owner` cannot be the zero address.
 * - `spender` cannot be the zero address.
 */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) public {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint256) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, "NFTDAO::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint256 delegatorBalance = _balances[delegator];
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _transferTokens(address src, address dst, uint256 amount) internal {
        require(src != address(0), "NFTDAO::_transferTokens: cannot transfer from the zero address");
        require(dst != address(0), "NFTDAO::_transferTokens: cannot transfer to the zero address");

        _balances[src] = _balances[src].sub( amount, "NFTDAO::_transferTokens: transfer amount exceeds balance");
        _balances[dst] = _balances[dst].add( amount);
        emit Transfer(src, dst, amount);

        _moveDelegates(delegates[src], delegates[dst], amount);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub( amount, "NFTDAO::_moveVotes: vote amount underflows");
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint256 oldVotes, uint256 newVotes) internal {
        uint32 blockNumber = safe32(block.number, "NFTDAO::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }


    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }

}

interface TimelockFactoryInterface {
    function TimelockMint(address admin_,uint delay_) external returns (address);
}

interface GovernorFactoryInterface {
    function GovernorMint(address nft_, uint supply_) external returns (address);

}

interface GovernorInstance {
    function init(address timelock) external;
}

/// @notice contract factory for the timelock interface
contract NFTDAOFactory {

    /// @notice event for creation
    event NewNFTDAO(address deployed);

    constructor() public {
    }

    /// minting function
    function NFTDAOMint(
        IERC721 nftAddress_,
        address owner_,
        uint256 tokenId_,
        uint256 totalSupply_,
        string memory name_,
        string memory symbol_,
        uint256 buyoutPrice_
    ) public returns (address) {
        NFTDAO newContract = new NFTDAO(
            nftAddress_,
            owner_,
            tokenId_,
            totalSupply_,
            name_,
            symbol_,
            buyoutPrice_
        );
        emit NewNFTDAO(address(newContract));
        return address(newContract);
    }
}
