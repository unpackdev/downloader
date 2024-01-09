// SPDX-License-Identifier: MIT

/**
 * @author          Yisi Liu
 * @contact         yisiliu@gmail.com
 * @author_time     01/06/2021
 * @maintainer      Hancheng Zhou, Yisi Liu, Andy Jiang
 * @maintain_time   06/15/2021
**/

pragma solidity >= 0.8.0;
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./SafeCast.sol";
import "./Initializable.sol";
import "./IQLF.sol";

contract HappyTokenPool is Initializable {
    struct Packed1 {
        address qualification_addr;
        uint40 password;
    }

    struct Packed2 {
        uint128 total_tokens;
        uint128 limit;
    }

    struct Packed3 {
        address token_address;
        uint32 start_time;
        uint32 end_time;
        uint32 unlock_time;
    }

    struct SwapStatus {
        bool claimed;
    }

    struct Pool {
        // CAUTION: DO NOT CHANGE ORDER & TYPE OF THESE VARIABLES
        // GOOGLE KEYWORDS "SOLIDITY, UPGRADEABLE CONTRACTS, STORAGE" FOR MORE INFO
        Packed1 packed1;
        Packed2 packed2;
        Packed3 packed3;
        address creator;
        address[] exchange_addrs;   // a list of ERC20 addresses for swapping
        uint128[] exchanged_tokens; // a list of amounts of swapped tokens
        uint128[] ratios;           // a list of swap ratios
                                    // length = 2 * exchange_addrs.length
                                    // [address1, target, address2, target, ...]
                                    // e.g. [1, 10]
                                    // represents 1 tokenA to swap 10 target token
                                    // note: each ratio pair needs to be coprime
        mapping(address => uint256) swapped_map;      // swapped amount of an address
        mapping(address => SwapStatus) swap_status;
        bool destructed;
    }

    // swap pool filling success event
    event FillSuccess (
        address indexed creator,
        bytes32 indexed id,
        uint256 total,
        uint256 creation_time,
        address token_address,
        string message,
        uint256 start,
        uint256 end,
        address[] exchange_addrs,
        uint128[] ratios,
        address qualification,
        uint256 limit
    );

    // swap success event
    event SwapSuccess (
        bytes32 indexed id,
        address indexed swapper,
        address from_address,
        address to_address,
        uint256 from_value,
        uint256 to_value,
        uint128 input_total,
        bool claimed
    );

    // claim success event
    event ClaimSuccess (
        bytes32 indexed id,
        address indexed claimer,
        uint256 timestamp,
        uint256 to_value,
        address token_address
    );

    // swap pool destruct success event
    event DestructSuccess (
        bytes32 indexed id,
        address indexed token_address,
        uint256 remaining_balance,
        uint128[] exchanged_values
    );

    // single token withdrawl from a swap pool success event
    event WithdrawSuccess (
        bytes32 indexed id,
        address indexed token_address,
        uint256 withdraw_balance
    );

    using SafeERC20 for IERC20;
    // CAUTION: DO NOT CHANGE ORDER & TYPE OF THESE VARIABLES
    // GOOGLE KEYWORDS "SOLIDITY, UPGRADEABLE CONTRACTS, STORAGE" FOR MORE INFO
    mapping(bytes32 => Pool) pool_by_id;    // maps an id to a Pool instance
    bytes32 private seed;
    address private DEFAULT_ADDRESS;
    uint64 public base_time;
    uint32 private nonce;

    function initialize(uint64 _base_time) public initializer {
        seed = keccak256(abi.encodePacked("MASK", block.timestamp, msg.sender));
        DEFAULT_ADDRESS = address(0);
        base_time = _base_time;
    }

    /**
     * @dev 
     * fill_pool() creates a swap pool with specific parameters from input
     * _hash                sha3-256(password)
     * _start               start time delta, real start time = base_time + _start
     * _end                 end time delta, real end time = base_time + _end
     * message              swap pool creation message, only stored in FillSuccess event
     * _exchange_addrs      swap token list (0x0 for ETH, only supports ETH and ERC20 now)
     * _ratios              swap pair ratio list
     * _unlock_time         unlock time delta real unlock time = base_time + _unlock_time
     * _token_addr          swap target token address
     * _total_tokens        target token total swap amount
     * _limit               target token single swap limit
     * _qualification       the qualification contract address based on IQLF to determine qualification
     * This function takes the above parameters and creates the pool. _total_tokens of the target token
     * will be successfully transferred to this contract securely on a successful run of this function.
    **/
    function fill_pool (bytes32 _hash, uint256 _start, uint256 _end, string memory _message,
                        address[] memory _exchange_addrs, uint128[] memory _ratios, uint256 _unlock_time,
                        address _token_addr, uint256 _total_tokens, uint256 _limit, address _qualification)
    public payable {
        nonce ++;
        require(_start < _end, "Start time should be earlier than end time.");
        require(_end < _unlock_time || _unlock_time == 0, "End time should be earlier than unlock time");
        require(_limit <= _total_tokens, "Limit needs to be less than or equal to the total supply");
        require(_total_tokens < 2 ** 128, "No more than 2^128 tokens(incluidng decimals) allowed");
        require(_exchange_addrs.length > 0, "Exchange token addresses need to be set");
        require(_ratios.length == 2 * _exchange_addrs.length, "Size of ratios = 2 * size of exchange_addrs");

        bytes32 _id = keccak256(abi.encodePacked(msg.sender, block.timestamp, nonce, seed));
        Pool storage pool = pool_by_id[_id];
        pool.packed1 = Packed1(_qualification, uint40(uint256(_hash) >> 216));
        pool.packed2 = Packed2(uint128(_total_tokens), uint128(_limit));
        pool.packed3 = Packed3(_token_addr, uint32(_start), uint32(_end), uint32(_unlock_time));
        pool.creator = msg.sender;
        pool.exchange_addrs = _exchange_addrs;
        pool.destructed = false;

        // Init each token swapped amount to 0
        for (uint256 i = 0; i < _exchange_addrs.length; i++) {
            if (_exchange_addrs[i] != DEFAULT_ADDRESS) {
                // TODO: Is there a better way to validate an ERC20?
                require(IERC20(_exchange_addrs[i]).totalSupply() > 0, "Not a valid ERC20");
            }
            pool.exchanged_tokens.push(0); 
        }

        pool.ratios = _ratios;                                          // 256 * k
        IERC20(_token_addr).safeTransferFrom(msg.sender, address(this), _total_tokens);

        {
            // Solidity has stack depth limitation: "Stack too deep, try removing local variables"
            // add local variables as a workaround
            uint256 total_tokens = _total_tokens;
            address token_addr = _token_addr;
            string memory message = _message;
            uint256 start = _start;
            uint256 end = _end;
            address[] memory exchange_addrs = _exchange_addrs;
            uint128[] memory ratios = _ratios;
            address qualification = _qualification;
            uint256 limit = _limit;

            emit FillSuccess(
                msg.sender,
                _id,
                total_tokens,
                block.timestamp,
                token_addr,
                message,
                start,
                end,
                exchange_addrs,
                ratios,
                qualification,
                limit
            );
        }
    }

    /**
     * @dev
     * swap() allows users to swap tokens in a swap pool
     * id                   swap pool id
     * verification         sha3-256(sha3-256(password)[:40]+swapper_address)
     * validation           sha3-256(swapper_address)
     * exchange_addr_i     the index of the exchange address of the list
     * input_total          the input amount of the specific token
     * This function is called by the swapper who approves the specific ERC20 or directly transfer the ETH
     * first and wants to swap the desired amount of the target token. The swapped amount is calculated
     * based on the pool ratio. After swap successfully, the same account can not swap the same pool again.
    **/

    function swap(
        bytes32 id,
        bytes32 verification,
        uint256 exchange_addr_i,
        uint128 input_total,
        bytes32[] memory data
    )
    public payable returns (uint256 swapped) {

        uint128 from_value = input_total;
        Pool storage pool = pool_by_id[id];
        Packed1 memory packed1 = pool.packed1;
        Packed2 memory packed2 = pool.packed2;
        Packed3 memory packed3 = pool.packed3;
        {
            bool qualified;
            string memory errorMsg;
            (qualified, errorMsg) = IQLF(packed1.qualification_addr).logQualified(msg.sender, data);
            require(qualified, errorMsg);
        }
        require (packed3.start_time + base_time < block.timestamp, "Not started.");
        require (packed3.end_time + base_time > block.timestamp, "Expired.");
        // sha3(sha3(passowrd)[:40] + msg.sender) so that the raw password will never appear in the contract
        require (
            verification == keccak256(abi.encodePacked(uint256(packed1.password), msg.sender)),
            'Wrong Password'
        );

        // revert if the pool is empty
        require (packed2.total_tokens > 0, "Out of Stock");

        address exchange_addr = pool.exchange_addrs[exchange_addr_i];
        uint256 ratioA = pool.ratios[exchange_addr_i*2];
        uint256 ratioB = pool.ratios[exchange_addr_i*2 + 1];
        // check if the input is enough for the desired transfer
        if (exchange_addr == DEFAULT_ADDRESS) {
            require(msg.value == from_value, 'No enough ether.');
        }

        uint128 swapped_tokens = SafeCast.toUint128(SafeMath.div(SafeMath.mul(from_value, ratioB), ratioA));
        require(swapped_tokens > 0, "Better not draw water with a sieve");

        if (swapped_tokens > packed2.limit) {
            // don't be greedy - you can only get at most limit tokens
            swapped_tokens = packed2.limit;
            // Update from_value
            from_value = SafeCast.toUint128(SafeMath.div(SafeMath.mul(packed2.limit, ratioA), ratioB));
        } else if (swapped_tokens > packed2.total_tokens ) {
            // if the left tokens are not enough
            swapped_tokens = packed2.total_tokens;
            // Update from_value
            from_value = SafeCast.toUint128(SafeMath.div(SafeMath.mul(packed2.total_tokens , ratioA), ratioB));
            // return the eth
            if (exchange_addr == DEFAULT_ADDRESS)
                payable(msg.sender).transfer(msg.value - from_value);
        }
        // make sure again
        require(swapped_tokens <= packed2.limit);
        // update exchanged
        pool.exchanged_tokens[exchange_addr_i] = SafeCast.toUint128(
            SafeMath.add(
                pool.exchanged_tokens[exchange_addr_i],
                from_value
            )
        );

        // penalize greedy attackers by placing duplication check at the very last
        require (pool.swapped_map[msg.sender] == 0, "Already swapped");

        // update the remaining tokens and swapped token mapping
        pool.packed2.total_tokens = SafeCast.toUint128(SafeMath.sub(packed2.total_tokens, swapped_tokens));
        pool.swapped_map[msg.sender] = swapped_tokens;

        // transfer the token after state changing
        // ETH comes with the tx, but ERC20 does not - INPUT
        if (exchange_addr != DEFAULT_ADDRESS) {
            IERC20(exchange_addr).safeTransferFrom(msg.sender, address(this), from_value);
        }

        {
            // Solidity has stack depth limitation: "Stack too deep, try removing local variables"
            // add local variables as a workaround
            // Swap success event
            bytes32 _id = id;
            uint128 _input_total = input_total;
            uint128 _from_value = from_value;
            bool claimed = false;
            if (packed3.unlock_time == 0) {
                claimed = true;
            }
            emit SwapSuccess(
                _id,
                msg.sender,
                exchange_addr,
                packed3.token_address,
                _from_value,
                swapped_tokens,
                _input_total,
                claimed
            );
        }

        // if unlock_time == 0, transfer the swapped tokens to the recipient address (msg.sender) - OUTPUT
        // if not, claim() needs to be called to get the token
        if (packed3.unlock_time == 0) {
            pool.swap_status[msg.sender].claimed = true;
            IERC20(packed3.token_address).safeTransfer(msg.sender, swapped_tokens);
            emit ClaimSuccess(id, msg.sender, block.timestamp, swapped_tokens, packed3.token_address);
        }
            
        return swapped_tokens;
    }

    /**
     * check_availability() returns a bunch of pool info given a pool id
     * id                    swap pool id
     * this function returns 1. exchange_addrs that can be used to determine the index
     *                       2. remaining target tokens
     *                       3. if started
     *                       4. if ended
     *                       5. swapped amount of the query address
     *                       5. exchanged amount of each token
    **/

    function check_availability (bytes32 id)
        external
        view
        returns (
            address[] memory exchange_addrs,
            uint256 remaining,
            bool started,
            bool expired,
            bool destructed,
            uint256 unlock_time,
            uint256 swapped,
            uint128[] memory exchanged_tokens,
            bool claimed,
            uint256 start_time,
            uint256 end_time,
            address qualification_addr
        )
    {
        Pool storage pool = pool_by_id[id];
        Packed3 memory packed3 = pool.packed3;
        uint256 _swapped_amount = pool.swapped_map[msg.sender];
        bool _claimed = false;
        if ( pool.swap_status[msg.sender].claimed ||
            ((_swapped_amount != 0) && (packed3.unlock_time == 0))) {
            _claimed = true;
        }
        return (
            pool.exchange_addrs,                                                // exchange_addrs
            pool.packed2.total_tokens,                                          // remaining
            block.timestamp > packed3.start_time + base_time,                   // started
            block.timestamp > packed3.end_time + base_time,                     // expired
            pool.destructed,
            packed3.unlock_time + base_time,                                    // unlock_time
            _swapped_amount,                                                    // swapped number
            pool.exchanged_tokens,                                              // exchanged tokens
            _claimed,                                                           // claimed?
            packed3.start_time + base_time,
            packed3.end_time + base_time,
            pool.packed1.qualification_addr
        );
    }

    function claim(bytes32[] calldata ito_ids) external {
        for (uint256 i = 0; i < ito_ids.length; i++) {
            Pool storage pool = pool_by_id[ito_ids[i]];
            Packed3 memory packed3 = pool.packed3;
            if (packed3.unlock_time == 0)
                continue;
            if (packed3.unlock_time + base_time > block.timestamp)
                continue;
            if (pool.swap_status[msg.sender].claimed)
                continue;
            uint256 claimed_amount = pool.swapped_map[msg.sender];
            if (claimed_amount == 0)
                continue;
            pool.swap_status[msg.sender].claimed = true;
            IERC20(packed3.token_address).safeTransfer(msg.sender, claimed_amount);
            emit ClaimSuccess(ito_ids[i], msg.sender, block.timestamp, claimed_amount, packed3.token_address);
        }
    }

    function setUnlockTime(bytes32 id, uint32 _unlock_time) public {
        Pool storage pool = pool_by_id[id];
        uint32 packed3_unlock_time = pool.packed3.unlock_time;
        require(pool.creator == msg.sender, "Pool Creator Only");
        require(block.timestamp < (packed3_unlock_time + base_time), "Too Late");
        require(packed3_unlock_time != 0, "Not eligible when unlock_time is 0");
        require(_unlock_time != 0, "Cannot set to 0");
        pool.packed3.unlock_time = _unlock_time;
    }

    /**
     * destruct() destructs the given pool given the pool id
     * id                    swap pool id
     * this function can only be called by the pool creator. after validation, it transfers all the remaining token 
     * (if any) and all the swapped tokens to the pool creator. it will then destruct the pool by reseting almost 
     * all the variables to zero to get the gas refund.
     * note that this function may not work if a pool needs to transfer over ~200 tokens back to the address due to 
     * the block gas limit. we have another function withdraw() to help the pool creator to withdraw a single token 
    **/

    function destruct (bytes32 id) public {
        Pool storage pool = pool_by_id[id];
        Packed3 memory packed3 = pool.packed3;
        require(msg.sender == pool.creator, "Only the pool creator can destruct.");

        uint256 expiration = pool.packed3.end_time + base_time;
        uint256 remaining_tokens = pool.packed2.total_tokens;
        // only after expiration or the pool is empty
        require(expiration <= block.timestamp || remaining_tokens == 0, "Not expired yet");

        if (pool.destructed) {
            return;
        }
        pool.destructed = true;

        // if any left in the pool
        if (remaining_tokens != 0) {
            IERC20(packed3.token_address).safeTransfer(msg.sender, remaining_tokens);
        }
        
        // transfer the swapped tokens accordingly
        // note this loop may exceed the block gas limit so if >200 exchange_addrs this may not work
        for (uint256 i = 0; i < pool.exchange_addrs.length; i++) {
            if (pool.exchanged_tokens[i] > 0) {
                // ERC20
                if (pool.exchange_addrs[i] != DEFAULT_ADDRESS)
                    IERC20(pool.exchange_addrs[i]).safeTransfer(msg.sender, pool.exchanged_tokens[i]);
                // ETH
                else
                    payable(msg.sender).transfer(pool.exchanged_tokens[i]);
            }
        }
        emit DestructSuccess(id, packed3.token_address, remaining_tokens, pool.exchanged_tokens);

        // Gas Refund
        pool.packed1 = Packed1(DEFAULT_ADDRESS, 0);
        pool.packed2 = Packed2(0, 0);
        for (uint256 i = 0; i < pool.exchange_addrs.length; i++) {
            pool.ratios[i*2] = 0;
            pool.ratios[i*2+1] = 0;
        }
    }
}
