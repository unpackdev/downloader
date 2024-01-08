// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./IERC721.sol";
import "./SafeMath.sol";
import "./Address.sol";

/// @author Alchemy Team
/// @title Alchemy
/// @notice The Alchemy contract wraps nfts into erc20
contract Alchemy is IERC20 {

    // using Openzeppelin contracts for SafeMath and Address
    using SafeMath for uint256;
    using Address for address;

    // presenting the total supply
    uint256 internal _totalSupply;

    // representing the name of the governance token
    string internal _name;

    // representing the symbol of the governance token
    string internal _symbol;

    // representing the decimals of the governance token
    uint8 internal constant _decimals = 18;

    // a record of balance of a specific account by address
    mapping(address => uint256) private _balances;

    // a record of allowances for a specific address by address to address mapping
    mapping(address => mapping(address => uint256)) private _allowances;

    // presenting the shares for sale
    uint256 public _sharesForSale;

    // struct for raised nfts
    struct _raisedNftStruct {
        IERC721 nftaddress;
        bool forSale;
        uint256 tokenid;
        uint256 price;
    }

    // The total number of NfTs in the DAO
    uint256 public _nftCount;

    // array for raised nfts
    _raisedNftStruct[] public _raisedNftArray;

    // mapping to store the already owned nfts
    mapping (address => mapping( uint256 => bool)) public _ownedAlready;

    // the buyout price. once its met, all nfts will be transferred to the buyer
    uint256 public _buyoutPrice;

    // the address which has bought the dao
    address public _buyoutAddress;

    // representing the governance contract of the nft
    address public _governor;

    // representing the timelock address of the nft for the governor
    address public _timelock;

    // factory contract address
    address public _factoryContract;

    // A record of each accounts delegate
    mapping (address => address) public delegates;

    // A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint256 votes;
        uint32 fromBlock;
    }

    // A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    // The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    // A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

    // Events
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);
    event Buyout(address buyer, uint256 price);
    event BuyoutTransfer(address nftaddress, uint256 nftid);
    event BurnedForEth(address account, uint256 reward);
    event SharesBought(address account, uint256 amount);
    event SharesBurned(uint256 amount);
    event SharesMinted(uint256 amount);
    event NewBuyoutPrice(uint256 price);
    event NftSaleChanged(uint256 nftid, uint256 price, bool sale);
    event SingleNftBought(address account, uint256 nftid, uint256 price);
    event NftAdded(address nftaddress, uint256 nftid);
    event NftTransferredAndAdded(address nftaddress, uint256 nftid);
    event TransactionExecuted(address target, uint256 value, string signature, bytes data);

    constructor() {
        // Don't allow implementation to be initialized.
        _factoryContract = address(1);
    }

    function initialize(
        IERC721[] memory nftAddresses_,
        address owner_,
        uint256[] memory tokenIds_,
        uint256 totalSupply_,
        string memory name_,
        string memory symbol_,
        uint256 buyoutPrice_,
        address factoryContract,
        address governor_,
        address timelock_
    ) external {
        require(_factoryContract == address(0), "already initialized");
        require(factoryContract != address(0), "factory can not be null");

        _factoryContract = factoryContract;
        _governor = governor_;
        _timelock = timelock_;

        // process the Nfts in the array
        for (uint i = 0; i < nftAddresses_.length; i++) {
            _raisedNftArray.push(_raisedNftStruct({
                nftaddress: nftAddresses_[i],
                tokenid: tokenIds_[i],
                forSale: false,
                price: 0
            }));

            _ownedAlready[address(nftAddresses_[i])][tokenIds_[i]] = true;
            _nftCount++;
        }

        _totalSupply = totalSupply_;
        _name = name_;
        _symbol = symbol_;
        _buyoutPrice = buyoutPrice_;
        _balances[owner_] = _totalSupply;
        emit Transfer(address(0), owner_, _totalSupply);
    }

    /**
    * @notice modifier only timelock can call these functions
    */
    modifier onlyTimeLock() {
        require(msg.sender == _timelock, "ALC:Only Timelock can call");
        _;
    }

    /**
    * @notice modifier only timelock or buyout address can call these functions
    */
    modifier onlyTimeLockOrBuyer() {
        require(msg.sender == _timelock || msg.sender == _buyoutAddress, "ALC:Only Timelock or Buyer can call");
        _;
    }

    /**
    * @notice modifier only if buyoutAddress is not initialized
    */
    modifier stillToBuy() {
        require(_buyoutAddress == address(0), "ALC:Already bought out");
        _;
    }

    /**
    * @dev Destroys `amount` tokens from `account`, reducing
    * and updating burn tokens for abstraction
    *
    * @param amount the amount to be burned
    */
    function _burn(uint256 amount) internal {
        _totalSupply = _totalSupply.sub(amount);
    }

    /**
    * @dev After a buyout token holders can burn their tokens and get a proportion of the contract balance as a reward
    */
    function burnForETH() external {
        uint256 balance = balanceOf(msg.sender);
        _balances[msg.sender] = 0;
        uint256 contractBalance = address(this).balance;
        uint256 cashOut = contractBalance.mul(balance).div(_totalSupply);
        _burn(balance);
        msg.sender.transfer(cashOut);

        emit BurnedForEth(msg.sender, cashOut);
        emit Transfer(msg.sender, address(0), balance);
    }

    /**
    * @notice Lets any user buy shares if there are shares to be sold
    *
    * @param amount the amount to be bought
    */
    function buyShares(uint256 amount) external payable {
        require(_sharesForSale >= amount, "low shares");
        require(msg.value == amount.mul(_buyoutPrice).div(_totalSupply), "low value");

        _balances[msg.sender] = _balances[msg.sender].add(amount);
        _sharesForSale = _sharesForSale.sub(amount);

        emit SharesBought(msg.sender, amount);
        emit Transfer(address(0), msg.sender, amount);
    }

    /**
    * @notice view function to get the discounted buyout price
    *
    * @param account the account
    */
    function getBuyoutPriceWithDiscount(address account) public view returns (uint256) {
        uint256 balance = _balances[account];
        return _buyoutPrice.mul((_totalSupply.sub(balance)).mul(10**18).div(_totalSupply)).div(10**18);
    }

    /**
    * @notice Lets anyone buyout the whole dao if they send ETH according to the buyout price
    * all nfts will be transferred to the buyer
    * also a fee will be distributed 0.5%
    */
    function buyout() external payable stillToBuy {
        uint256 buyoutPriceWithDiscount = getBuyoutPriceWithDiscount(msg.sender);
        require(msg.value == buyoutPriceWithDiscount, "buy value not met");

        uint256 balance = _balances[msg.sender];
        _balances[msg.sender] = 0;
        _burn(balance);

        // Take 0.5% fee
        address payable alchemyRouter = IAlchemyFactory(_factoryContract).getAlchemyRouter();
        IAlchemyRouter(alchemyRouter).deposit{value:buyoutPriceWithDiscount / 200}();

        // set buyer address
        _buyoutAddress = msg.sender;

        emit Buyout(msg.sender, buyoutPriceWithDiscount);
        emit Transfer(msg.sender, address(0), balance);
    }

    /**
    * @notice transfers specific nfts after the buyout happened
    *
    * @param nftids the array of nft ids
    */
    function buyoutWithdraw(uint[] memory nftids) external {
        require(msg.sender == _buyoutAddress, "can only be called by the buyer");

        _raisedNftStruct[] memory raisedNftArray = _raisedNftArray;

        for (uint i=0; i < nftids.length; i++) {
            raisedNftArray[nftids[i]].nftaddress.safeTransferFrom(address(this), msg.sender, raisedNftArray[nftids[i]].tokenid);
            emit BuyoutTransfer(address(raisedNftArray[nftids[i]].nftaddress), raisedNftArray[nftids[i]].tokenid);
        }
    }

    /**
    * @notice decreases shares for sale on the open market
    *
    * @param amount the amount to be burned
    */
    function burnSharesForSale(uint256 amount) onlyTimeLock external {
        require(_sharesForSale >= amount, "Low shares");

        _burn(amount);
        _sharesForSale = _sharesForSale.sub(amount);

        emit SharesBurned(amount);
        emit Transfer(msg.sender, address(0), amount);
    }

    /**
    * @notice increases shares for sale on the open market
    *
    * @param amount the amount to be minted
    */
    function mintSharesForSale(uint256 amount) onlyTimeLock external {
        _totalSupply = _totalSupply.add(amount);
        _sharesForSale = _sharesForSale.add(amount);

        emit SharesMinted(amount);
        emit Transfer(address(0), address(this), amount);
    }

    /**
    * @notice changes the buyout price for the whole dao
    *
    * @param amount to set the new price
    */
    function changeBuyoutPrice(uint256 amount) onlyTimeLock external {
        _buyoutPrice = amount;
        emit NewBuyoutPrice(amount);
    }

    /**
    * @notice allows the dao to set a specific nft on sale or to close the sale
    *
    * @param nftarrayid the nftarray id
    * @param price the buyout price for the specific nft
    * @param sale bool indicates the sale status
    */
    function setNftSale(uint256 nftarrayid, uint256 price, bool sale) onlyTimeLock external {
        _raisedNftArray[nftarrayid].forSale = sale;
        _raisedNftArray[nftarrayid].price = price;

        emit NftSaleChanged(nftarrayid, price, sale);
    }

    /**
    * @notice allows anyone to buy a specific nft if it is on sale
    * takes a fee of 0.5% on sale
    * @param nftarrayid the nftarray id
    */
    function buySingleNft(uint256 nftarrayid) stillToBuy external payable {
        _raisedNftStruct memory singleNft = _raisedNftArray[nftarrayid];

        require(singleNft.forSale, "Not for sale");
        require(msg.value == singleNft.price, "Price too low");

        // Take 0.5% fee
        address payable alchemyRouter = IAlchemyFactory(_factoryContract).getAlchemyRouter();
        IAlchemyRouter(alchemyRouter).deposit{value:singleNft.price / 200}();

        _ownedAlready[address(singleNft.nftaddress)][singleNft.tokenid] = false;
        _nftCount--;

        for (uint i = nftarrayid; i < _raisedNftArray.length - 1; i++) {
            _raisedNftArray[i] = _raisedNftArray[i+1];
        }
        _raisedNftArray.pop();

        singleNft.nftaddress.safeTransferFrom(address(this), msg.sender, singleNft.tokenid);

        emit SingleNftBought(msg.sender, nftarrayid, singleNft.price);
    }

    /**
    * @notice adds a new nft to the nft array
    * must be approved and transferred extra
    *
    * @param new_nft the address of the new nft
    * @param tokenid the if of the nft token
    */
    function addNft(address new_nft, uint256 tokenid) onlyTimeLockOrBuyer public {
        require(_ownedAlready[new_nft][tokenid] == false, "ALC: Cant add duplicate NFT");
        _raisedNftStruct memory temp_struct;
        temp_struct.nftaddress = IERC721(new_nft);
        temp_struct.tokenid = tokenid;
        _raisedNftArray.push(temp_struct);
        _nftCount++;

        _ownedAlready[new_nft][tokenid] = true;
        emit NftAdded(new_nft, tokenid);
    }

    /**
    * @notice transfers an NFT to the DAO contract (called by executeTransaction function)
    *
    * @param new_nft the address of the new nft
    * @param tokenid the if of the nft token
    */
    function transferFromAndAdd(address new_nft, uint256 tokenid) onlyTimeLockOrBuyer public {
        IERC721(new_nft).transferFrom(IERC721(new_nft).ownerOf(tokenid), address(this), tokenid);
        addNft(new_nft, tokenid);

        emit NftTransferredAndAdded(new_nft, tokenid);
    }

    /**
    * @notice adds an NFT collection to the DAO contract
    *
    * @param new_nft_array the address of the new nft
    * @param tokenid_array the id of the nft token
    */
    function addNftCollection(address[] memory new_nft_array, uint256[] memory tokenid_array) onlyTimeLockOrBuyer public {
        for (uint i = 0; i <= new_nft_array.length - 1; i++) {
            addNft(new_nft_array[i], tokenid_array[i]);
        }
    }

    /**
    * @notice transfers an NFT collection to the DAO contract
    *
    * @param new_nft_array the address of the new nft
    * @param tokenid_array the id of the nft token
    */
    function transferFromAndAddCollection(address[] memory new_nft_array, uint256[] memory tokenid_array) onlyTimeLockOrBuyer public {
        for (uint i = 0; i <= new_nft_array.length - 1; i++) {
            transferFromAndAdd(new_nft_array[i], tokenid_array[i]);
        }
    }

    /**
    * @notice executes any transaction
    *
    * @param target the target of the call
    * @param value the value of the call
    * @param signature the signature of the function call
    * @param data the calldata
    */
    function executeTransaction(address target, uint256 value, string memory signature, bytes memory data) onlyTimeLock external payable returns (bytes memory) {
        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{value:value}(callData);
        require(success, "ALC:exec reverted");

        emit TransactionExecuted(target, value, signature, data);
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
    function decimals() public pure returns (uint8) {
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
        return _balances[account];
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
    fallback() external payable {}

    receive() external payable {}

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
            uint256 newAllowance = spenderAllowance.sub(amount, "NFTDAO:amount exceeds");
            _allowances[src][spender] = newAllowance;
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
        require(owner != address(0), "ERC20: approve from 0");
        require(spender != address(0), "ERC20: approve to 0");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from 0");
        require(recipient != address(0), "ERC20: transfer to 0");
        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds"
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
        require(blockNumber < block.number, "ALC:getPriorVotes");

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
        require(src != address(0), "ALC: cannot transfer 0");
        require(dst != address(0), "ALC: cannot transfer 0");

        _balances[src] = _balances[src].sub( amount, "ALC:_transferTokens");
        _balances[dst] = _balances[dst].add( amount);
        emit Transfer(src, dst, amount);

        _moveDelegates(delegates[src], delegates[dst], amount);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub( amount, "ALC:_moveVotes");
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
        uint32 blockNumber = safe32(block.number, "ALC:_writeCheck");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(newVotes, blockNumber);
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


interface IAlchemyFactory {
    function getAlchemyRouter() external view returns (address payable);
}

interface IAlchemyRouter {
    function deposit() external payable;
}