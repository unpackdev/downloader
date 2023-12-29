pragma solidity 0.8.18;
// SPDX-License-Identifier: MIT

/*

The social engagement revolution.
Personal XP, buybacks, LP burns, lotteries, airdrops, and much more! 
Telegram: https://t.me/SocialAIPortal
Website: https://www.socialai.finance/

*/

library TransferHelper {

    // To make sure the correct transfers if called and reverts are caught in "success"

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
}
 
interface IUniswapRouter {

    function WETH() external pure returns (address);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
        ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function factory() external pure returns (address);
}

interface IUniswapFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IERC20 {
    function approve(address spender, uint amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address holder, address spender) external view returns(uint256);
}

contract SocialAIEngaged {

    struct Project {
        uint256 project_id;
        address token;
        address owner;
        uint256 eth_balance;
        uint256 tokens_reserved;
        bool active;
    }
    
    address public DAPP_controller; // wallet used to sign automatic DAPP interactions
    address public sai_fee_wallet;
    address public gas_wallet;

    mapping(uint => address) public allowed_token;
    mapping(uint => Project) public projects;


    address private constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address private constant ZERO = 0x0000000000000000000000000000000000000000;
    IUniswapRouter private constant uniswapRouter = IUniswapRouter(UNISWAP_ROUTER_ADDRESS);


    uint256 public sai_reserved;
    uint256 public gas_reserved;
    uint256 public send_gas_at = 0.05 ether;

    bool public safety_enabled = true;


    // Access control 
    constructor() {
        DAPP_controller = msg.sender;
        gas_wallet = msg.sender;
        sai_fee_wallet = msg.sender;
    }

    modifier only_DAPP() {
        require(msg.sender == DAPP_controller, "Caller not DAPP"); _;
    }

    // BASIC CONTRACT CONTROL
    function DAPP_set_DAPP_controller(address new_controller) external only_DAPP {
        DAPP_controller = new_controller;
    }

    function DAPP_set_gas_wallet(address new_gas_wallet) external only_DAPP {
        gas_wallet = new_gas_wallet;
    }

    function DAPP_set_sai_fee_wallet(address new_fee_wallet) external only_DAPP {
        sai_fee_wallet = new_fee_wallet;
    }

    function DAPP_withdraw_sai_fee() external only_DAPP {
        payable(sai_fee_wallet).transfer(sai_reserved);
        sai_reserved = 0;
    }

    function DAPP_manual_withdraw_gas_fee() external only_DAPP {
        payable(gas_wallet).transfer(gas_reserved);
        gas_reserved = 0;
    }

    function DAPP_set_send_threshold(uint new_threshold) external only_DAPP {
        send_gas_at = new_threshold;
    }

    // INTERNAL HELPERS
    function _swap_eth_for_tokens(address token, uint256 ethAmount, address to) internal returns (uint tokensBought) {
        // Define the token to swap and the path to swap it
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = token;

        // Swap the ETH for the token, and check how much we gained 
        uint balBefore = IERC20(token).balanceOf(address(this));
        uniswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(0, path, to, block.timestamp+1);
        tokensBought = IERC20(token).balanceOf(address(this)) - balBefore;
    }

    function _charge_fee(uint project_id, uint256 amount, uint256 sai_fee, uint256 gas_fee_of_prev_tx, bool is_eth) internal {
        // Is this a valid project
        require(projects[project_id].active, "Not active");

        // Check for enough balance
        uint256 total_eth = 0;

        if (is_eth) {
            // The fee equal the total amount of ETH + fees
            total_eth = amount + sai_fee + gas_fee_of_prev_tx;

        } else {
            // Check if the token address is set otherwise tokens cannot be reserved
            require(projects[project_id].token != address(0), "Token not set");

            // In case of a token, we have to charge ETH seperately
            total_eth = sai_fee + gas_fee_of_prev_tx;
            
            // Check for enough tokens
            uint token_balance = IERC20(projects[project_id].token).balanceOf(address(this));
            uint tokens_available = token_balance - projects[project_id].tokens_reserved;
            require(amount <= tokens_available, "TOKEN: not enough avaiable");
            
            // Reserve the tokens
            projects[project_id].tokens_reserved += amount;
        }
        
        // Check for enough ETH and reduce balance
        require(total_eth <= projects[project_id].eth_balance, "ETH: Not enough balance");
        projects[project_id].eth_balance -= total_eth;

        // Update the fee reserved for the SAI ecosystem
        sai_reserved += sai_fee;
        gas_reserved += gas_fee_of_prev_tx;

        // Should we send ETH
        if (gas_reserved >= send_gas_at) {
            payable(DAPP_controller).transfer(gas_reserved);
            gas_reserved = 0;
        }        
    }

    function _check_merkle_tree(bytes32 airdrop_hash, bytes32[] memory _witnesses, uint256 path) internal view returns(bool) {
        bytes32 merkleRoot = merkle_root_hash[airdrop_hash];  
        require(merkleRoot != bytes32(0), "No merkle airdrop");  
        bytes32 node = keccak256(abi.encodePacked(uint8(0x00), msg.sender));
        for (uint16 i = 0; i < _witnesses.length; i++) {
            if ((path & 0x01) == 1) {
                node = keccak256(abi.encodePacked(uint8(0x01), _witnesses[i], node));
            } else {
                node = keccak256(abi.encodePacked(uint8(0x01), node, _witnesses[i]));
            }
            path /= 2;
        }
        return node == merkleRoot;
    }

    function _finalize_airdrop(bytes32 airdrop_hash, uint project_id) internal {
        Airdrop memory current_drop = airdrops[airdrop_hash];
        uint refund = current_drop.drops_left * current_drop.amount;
        if (current_drop.is_eth) {
            projects[project_id].eth_balance += refund;
        } else {
            // can reset the reserved tokens
            projects[project_id].tokens_reserved -= refund;
        }
        delete airdrops[airdrop_hash];
    }

    function _charge_just_gas(uint project_id, uint gas_fee) internal {
        require(gas_fee <= projects[project_id].eth_balance, "Cant cover gas");
        projects[project_id].eth_balance -= gas_fee;
    }

    // PROJECT CREATION
    function DAPP_set_verified_token(uint project_id, address token, uint gas_prev_tx) external only_DAPP {
        _charge_just_gas(project_id, gas_prev_tx);
        projects[project_id].token = token;
        IERC20(token).approve(UNISWAP_ROUTER_ADDRESS, 2**256 - 1); // approve on router so we don't have to do this later
    }

    function DAPP_create_SAI_engaged_project(uint project_id, address wallet, address token) external only_DAPP {
        require(projects[project_id].owner == address(0), "Already exists");
    
        // Create the project struct
        Project memory p = Project(project_id, token, wallet, 0, 0, true);
        projects[project_id] = p;
        
        // Approve if token address is given 
         if (token != address(0)) {
            IERC20(token).approve(UNISWAP_ROUTER_ADDRESS, 2**256 - 1);
        }
    }

    // EXTERNAL PROJECT INTERACTIONS
    function deposit_eth_to_project(uint project_id) external payable {
        require(msg.value > 0, "No ETH");
        require(projects[project_id].active, "Not active");
        projects[project_id].eth_balance += msg.value;
    }

    function deposit_tokens_to_project(address token, uint256 token_amount) external {
        // requires token approval first 
        TransferHelper.safeTransferFrom(token, msg.sender, address(this), token_amount);
    }

    function change_project_owner(uint project_id, address new_owner) external {
        require(msg.sender == projects[project_id].owner, "Sender != owner");
        projects[project_id].owner = new_owner;
    }

    // AUTOMATIC GROUP REWARDS
    function DAPP_buyback_and_burn(uint project_id, uint256 amount, uint256 sai_fee, uint256 gas_prev_tx) external only_DAPP {
        // Check whether this tx can be executed and adjust the projects balance
        _charge_fee(project_id, amount, sai_fee, gas_prev_tx, true);
        address token = projects[project_id].token;
        require(token != address(0), "Token not set");
        _swap_eth_for_tokens(token, amount, DEAD); 
    }
    
    function DAPP_add_lp_and_burn(uint project_id, uint amount, uint256 sai_fee, uint256 gas_prev_tx) external only_DAPP  {
        _charge_fee(project_id, amount, sai_fee, gas_prev_tx, true); 
        // Use half of the ETH to buy tokens 
        address token = projects[project_id].token;
        require(token != address(0), "Token not set");
        uint256 tokensOut = _swap_eth_for_tokens(token, amount/2, address(this));        
        // Add the tokens to the pool 
        uniswapRouter.addLiquidityETH{value: amount/2}(token, tokensOut, 0, 0, DEAD, block.timestamp);
    }

    // PERSONAL - LOTTERIES

    mapping(bytes32 => uint256) public lottery_amount;
    mapping(bytes32 => bool)    public lottery_is_eth;

    function DAPP_award_lottery(uint project_id, uint lottery_id, address[] memory winners, uint[] memory amounts, uint gas_prev_tx) external only_DAPP {
        require(winners.length == amounts.length, "Length winners != amounts");
        bytes32 lottery_hash = keccak256(abi.encodePacked(project_id, lottery_id));

        // Just charge the gas for awards, sai fee was paid upon creation
        _charge_just_gas(project_id, gas_prev_tx);

        bool is_eth = lottery_is_eth[lottery_hash];
        uint tot_awarded = 0;
        
        for (uint i=0; i<winners.length; i++) {
            uint amount = amounts[i]; // Amounts can be different for different winners 
            tot_awarded += amount;

            // Check if we need to send ETH or tokens
            address winner = winners[i];
            if (is_eth) {
                payable(winner).transfer(amount);
            } else {
                TransferHelper.safeTransfer(projects[project_id].token, winner, amount);
            }
        }

        // Make sure not more is spent than initially allocated
        uint256 tot_reserved = lottery_amount[lottery_hash];
        require(tot_reserved > 0, "Lottery does not exist/is over");
        require(tot_awarded <= tot_reserved, "Spent more than reserved");

        // If something is left refund 
        if (is_eth) {
            uint256 refund_amount = tot_reserved - tot_awarded;
            projects[project_id].eth_balance += refund_amount;
        } else {
            // Nothing is reserved anymore, regardless of what was awarded
            projects[project_id].tokens_reserved -= tot_reserved;
        }

        // Lottery is over so reset amount hash, whether it is ETH does 
        // not matter cause it will be reset anyway for new lotteries
        lottery_amount[lottery_hash] = 0 ;
    }

    function DAPP_create_lottery(uint project_id, uint lottery_id, uint tot_amount, bool is_eth, uint sai_fee, uint gas_prev_tx) external only_DAPP {
        _charge_fee(project_id, tot_amount, sai_fee, gas_prev_tx, is_eth); // Will automatically reserve the tokens + check if active
        require(tot_amount > 0, "Lottery amount cannot be 0");
        bytes32 lottery_hash = keccak256(abi.encodePacked(project_id, lottery_id));
        require(lottery_amount[lottery_hash] == 0, "Lottery ongoing");
        lottery_amount[lottery_hash] = tot_amount;
        lottery_is_eth[lottery_hash] = is_eth;
    }

    // PERSONAL - AIRDROPS
    struct Airdrop {
        uint amount;
        uint expires_at;
        bool is_eth;
        bool is_active;
        uint total_drops;
        uint drops_left;
    }

    mapping(bytes32 => Airdrop) airdrops; // hash project id and airdrop id
    mapping(bytes32 => bool) airdrop_claimed;
    mapping(bytes32 => bytes32) merkle_root_hash; // Only applicable to merkle root airdrops
    
    function DAPP_create_airdrop(uint project_id, uint airdrop_id, uint airdrop_amount, uint number_of_airdrops, bytes32 merkle_root,
     uint expire_stamp, bool is_eth, uint sai_fee, uint gas_prev_tx) external only_DAPP {
        // Check how much ETH/tokens in total would be needed for the airdrop
        uint tot_amount = airdrop_amount * number_of_airdrops;

         // Reserve/subtract balance to pre reserve
        _charge_fee(project_id, tot_amount, sai_fee, gas_prev_tx, is_eth);

         // Get the hash and check if this exists already
        bytes32 airdrop_hash = keccak256(abi.encodePacked(project_id, airdrop_id));
        require(airdrops[airdrop_hash].is_active == false, "Already there");

        // Allocate the airdrop struct
        Airdrop memory drop = Airdrop(airdrop_amount, expire_stamp, is_eth, true, number_of_airdrops, number_of_airdrops);
        airdrops[airdrop_hash] = drop;

        // In case a merkle root is given, we use that 
        if (merkle_root != bytes32(0)) {
            merkle_root_hash[airdrop_hash] = merkle_root;
        }
    }
 
    function DAPP_extend_airdrop(uint project_id, uint airdrop_id, uint new_expire_stamp, uint gas_prev_tx) external only_DAPP {
        _charge_just_gas(project_id, gas_prev_tx);
        bytes32 airdrop_hash = keccak256(abi.encodePacked(project_id, airdrop_id));
        airdrops[airdrop_hash].expires_at = new_expire_stamp;
    }
    
    function DAPP_update_merkle_airdrop(uint project_id, uint airdrop_id, bytes32 new_merkle_root, uint gas_prev_tx) external only_DAPP {
        _charge_just_gas(project_id, gas_prev_tx);
        bytes32 airdrop_hash = keccak256(abi.encodePacked(project_id, airdrop_id));

        // Check if this was a merkle in the first place
        require(merkle_root_hash[airdrop_hash] != bytes32(0), "AIRDROP: not a merkle");

        // Update the root and reactivate
        merkle_root_hash[airdrop_hash] = new_merkle_root;
        airdrops[airdrop_hash].is_active = true; // usually we will temp disable the airdrop to prevent frontruns (unless send in private txns)
    }

    function DAPP_distribute_bulk_airdrop(uint project_id, uint airdrop_id, address[] memory receivers, uint gas_prev_tx) external  only_DAPP {
        _charge_just_gas(project_id, gas_prev_tx);

        bytes32 airdrop_hash = keccak256(abi.encodePacked(project_id, airdrop_id));

        Airdrop memory current_drop = airdrops[airdrop_hash];
        
        // Verify if this is actually an airdrop meant to be distributes manually
        require(merkle_root_hash[airdrop_hash] == bytes32(0), "AIRDROP: This is not a bulk drop");
        require(current_drop.is_active, "AIRDROP: Inactive");

        // Since we do this every 24 hours we sometimes might distribute after ending a drop
        // as extra safety, we only allow distributing up to 2 days after but not after this 
        // anymore
        require(block.timestamp <= current_drop.expires_at + 2 days, "Distribute expired");

        uint airdrop_amount = current_drop.amount;
        address token = projects[project_id].token;

        // Transfer to tokens to receivers
        uint dropped = 0;
        for (uint i = 0; i < receivers.length; i++) {
            address receiver = receivers[i];

            // Send out the tokens or eth 
            if (current_drop.is_eth) {
                payable(receiver).transfer(airdrop_amount);
            } else {
                TransferHelper.safeTransfer(token, receiver, airdrop_amount);
            }
            
            // Keep check of drop count to make sure not more is dropped than intended
            dropped += 1;
        }

        require(dropped <= current_drop.drops_left, "No drops left!");
        airdrops[airdrop_hash].drops_left -= dropped;

        // Update reserved tokens (if applicable)
        if (!current_drop.is_eth) {
            projects[project_id].tokens_reserved -= (dropped * current_drop.amount);
        }
        
        // auto-finalize
        if (airdrops[airdrop_hash].drops_left  == 0) {
            _finalize_airdrop(airdrop_hash, project_id);
        }
    }

    function claim_airdrop(uint256 path, bytes32[] memory witness, uint project_id, uint256 airdrop_id) external {
        bytes32 sender_hash = keccak256(abi.encodePacked(msg.sender, project_id, airdrop_id));
        bytes32 airdrop_hash = keccak256(abi.encodePacked(project_id, airdrop_id));
        
        Airdrop memory current_drop = airdrops[airdrop_hash];

        require(!airdrop_claimed[sender_hash],                          "CLAIM: Already claimed");
        require(_check_merkle_tree(airdrop_hash, witness, path),        "CLAIM: Not whitelisted");
        require(current_drop.is_active,                                 "CLAIM: Airdrop inactive"); // Frontrun safety by first deactivating
        require(block.timestamp <= current_drop.expires_at + 2 days,    "CLAIM: Drop Expired!");    // Whitelist gets updated every 24 hours as well, so allow some slack

        airdrop_claimed[sender_hash] = true;
        
        require(airdrops[airdrop_hash].drops_left >= 1, "CLAIM: no drops left");
        airdrops[airdrop_hash].drops_left -= 1;

        if (current_drop.is_eth) {
           payable(msg.sender).transfer(current_drop.amount);
        } else {
            TransferHelper.safeTransfer(projects[project_id].token, msg.sender, current_drop.amount);
            projects[project_id].tokens_reserved -= current_drop.amount;
        }

        // auto-finalize
        if (airdrops[airdrop_hash].drops_left  == 0) {
            _finalize_airdrop(airdrop_hash, project_id);
        }
    }

    function DAPP_finalize_airdrop(uint project_id, uint airdrop_id) external only_DAPP {
        bytes32 airdrop_hash = keccak256(abi.encodePacked(project_id, airdrop_id));
        
        // Check if this can be called yet
        if (airdrops[airdrop_hash].drops_left > 0) {
           require(block.timestamp >= airdrops[airdrop_hash].expires_at + 2 days, "Cant refund yet");
        }

        _finalize_airdrop(airdrop_hash, project_id);
    }

    // We need to adjust airdrop when we update the merkle-root to prevent front running to be in two batches
    // we can skip this when the update txs are submitted on private RPC
    function DAPP_temp_disable_airdrop(uint project_id, uint airdrop_id, bool status) public only_DAPP {
        bytes32 airdrop_hash = keccak256(abi.encodePacked(project_id, airdrop_id));
        airdrops[airdrop_hash].is_active = status;
    }
    
    // TERMINATORS
    // While terminate will kill the project it's possible to withdraw everything that is currently
    // not reserved for a lottery ot airdrop. However, this will cause issues with the bounties
    // and hence should be executed  by the DAPP after deleting active bounties
    function DAPP_withdraw_partial(uint project_id, uint gas_fee_of_prev_tx) external only_DAPP {
        Project memory project = projects[project_id];
        require(project.active, "Non existent");

        // ETH side
        require(gas_fee_of_prev_tx <= project.eth_balance, "Cant cover gas refund");
        uint eth_to_refund = project.eth_balance - gas_fee_of_prev_tx;
        if (eth_to_refund > 0) {
            projects[project_id].eth_balance = 0; 
            gas_reserved += gas_fee_of_prev_tx;
            payable(project.owner).transfer(eth_to_refund);
        }

        // Token side, note the difference is that only non reserved tokens are send
        if (project.token != address(0)) {
            
            // All tokens in the contract
            uint total_tokens = IERC20(project.token).balanceOf(address(this));

            // Unreserved tokens
            uint tokens_to_refund = total_tokens - project.tokens_reserved;
            if (tokens_to_refund > 0) {
                TransferHelper.safeTransfer(project.token, project.owner, tokens_to_refund);
            }
        }

    }

    // Note this will send as much as we can, this includes tokens reserved for lotteries or airdrops
    // rendering those invalid. There will be no additional checks if this ETH still exists when awarding
    // hence this only should be used when the DAPP erased every record for this project prior to calling
    function DAPP_terminate_project(uint project_id, uint gas_fee_of_prev_tx) external only_DAPP {
        Project memory project = projects[project_id];
        require(project.active, "Non existent");
        
        // ETH side
        require(gas_fee_of_prev_tx <= project.eth_balance, "Cant cover gas refund");
        uint eth_to_refund = project.eth_balance - gas_fee_of_prev_tx;
        if (eth_to_refund > 0) {
            project.eth_balance = 0; 
            gas_reserved += gas_fee_of_prev_tx;
            payable(project.owner).transfer(eth_to_refund);
        }
     
        // Token side 
        if (project.token != address(0)) {
            // All tokens in the contract
            uint tokens_to_refund = IERC20(project.token).balanceOf(address(this));
            if (tokens_to_refund > 0) {
                TransferHelper.safeTransfer(project.token, project.owner, tokens_to_refund);
            }
        }

        // Remove project, this will invalidate current bounties
         delete projects[project_id];

    }

    function DAPP_withdraw_all_eth() external only_DAPP {
        require(safety_enabled, "Can't use this anymore");
        payable(DAPP_controller).transfer(address(this).balance);
    }

    function DAPP_send_token(address token, uint amount) external only_DAPP {
        require(safety_enabled, "Can't use this anymore");
        TransferHelper.safeTransfer(token, DAPP_controller, amount);
    }

    // Only call this when sure contract is functioning as expected
    // this will remove the possibility to send out ETH and tokens
    // in case it would get stuck
    function DAPP_permanantely_revoke_safety() external only_DAPP {
        safety_enabled = false;
    }

    receive() external payable {}


    // BASE - some info view functions
    function project_token_balance(uint project_id) public view returns(uint) {
        address token = projects[project_id].token;
        return IERC20(token).balanceOf(address(this));
    }

    function burned_tokens(uint project_id) external view returns(uint) {
        return IERC20(projects[project_id].token).balanceOf(DEAD);
    }

    function get_pair(uint project_id) public view returns(address) {
        address tokenA = projects[project_id].token; 
        address tokenB = uniswapRouter.WETH();
        address pairTokens =  IUniswapFactory(uniswapRouter.factory()).getPair(tokenA, tokenB);
        return pairTokens;
    }

    function burned_lp(uint project_id) external view returns(uint) {
        address pairTokens = get_pair(project_id);
        return IERC20(pairTokens).balanceOf(DEAD);
    }

    function check_token_balance(uint project_id, address wallet) external view returns(uint) {
        return IERC20(projects[project_id].token).balanceOf(wallet);
    }



}