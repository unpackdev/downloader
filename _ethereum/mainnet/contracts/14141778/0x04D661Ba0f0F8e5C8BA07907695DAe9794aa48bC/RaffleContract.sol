pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "Ownable.sol";
import "SafeMath.sol";
import "IERC20.sol";
import "IERC721.sol";
import "UniformRandomNumber.sol";
import "SortitionSumTreeFactory.sol";
import "IGVRF.sol";

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

/*TODO:
upgrade to safemath
upgrade to upgradeable
*/

/*
CONTRACT GAMEDROP RAFFLE
*/

contract RaffleContract is Ownable {
    //libraries
    using SortitionSumTreeFactory for SortitionSumTreeFactory.SortitionSumTrees;

    //constansts and variables for sortition
    bytes32 private constant TREE_KEY = keccak256("Gamedrop/Raffle");
    uint256 private constant MAX_TREE_LEAVES = 5; //chose this constant to balance cost of read vs write. Could be optimized with data
    SortitionSumTreeFactory.SortitionSumTrees internal sortition_sum_trees;

    //structs
    struct NFT {
        IERC721 nft_contract;
        uint256 token_id;
    }
    struct NextEpochBalanceUpdate {
        address user;
        uint256 new_balance;
    }

    //contract interfaces
    IERC20 public gaming_test_token;
    IGVRF public gamedrop_vrf_contract;

    //variables for raffle
    uint256 total_token_entered;
    uint256 total_time_weighted_balance;
    uint256 last_raffle_time;
    bytes32 current_random_request_id;

    //variables for claimable prize
    address public most_recent_raffle_winner;
    NFT public most_recent_prize;

    //array for owned NFTs
    NFT[] public vaultedNFTs;
    mapping(IERC721 => mapping(uint256 => bool)) is_NFT_in_vault;
    mapping(IERC721 => mapping(uint256 => uint256)) index_of_nft_in_array;

    //array to hold instructions for updating balances post raffle and mappings
    address[] next_epoch_balance_instructions;
    mapping(address => bool) is_user_already_in_next_epoch_array;
    mapping(address => uint256) user_to_old_balance;
    mapping(address => uint256) user_to_new_balance;

    //token and time weighted balances
    mapping(address => uint256) public raw_balances;

    //whitelists
    mapping(address => bool) private _address_whitelist;
    mapping(IERC721 => bool) private _nft_whitelist;

    event depositMade(
        address sender,
        uint256 amount,
        uint256 total_token_entered
    );
    event withdrawMade(
        address sender,
        uint256 amount,
        uint256 total_token_entered
    );
    event NFTVaulted(address sender, IERC721 nft_contract, uint256 token_id);
    event AddressWhitelist(address whitelist_address);
    event NFTWhitelist(IERC721 nft_address);
    event NFTsent(
        address nft_recipient,
        IERC721 nft_contract_address,
        uint256 token_id
    );
    event raffleInitiated(uint256 time, bytes32 request_id, address initiator);
    event raffleCompleted(uint256 time, address winner, NFT prize);

    constructor(address _deposit_token) {
        //initiate countdown to raffle at deploy time
        last_raffle_time = block.timestamp;

        //initialize total_token_entered at 0
        total_token_entered = 0;

        //initialize ERC20 interface (in production this will be yield guild)
        gaming_test_token = IERC20(_deposit_token);

        //initialize sortition_sum_trees
        sortition_sum_trees.createTree(TREE_KEY, MAX_TREE_LEAVES);
    }

    modifier addRaffleBalance(uint256 amount) {
        // declare time_between_raffles in memory in two functions to save gas
        uint256 time_between_raffles = 604800;
        uint256 time_until_next_raffle = (time_between_raffles -
            (block.timestamp - last_raffle_time));
        uint256 updated_balance = time_until_next_raffle * amount;

        raw_balances[msg.sender] += amount;

        // creates or updates node in sortition tree for time weighted odds of user
        sortition_sum_trees.set(
            TREE_KEY,
            updated_balance,
            bytes32(uint256(uint160(msg.sender)))
        );

        _;

        uint256 next_balance = raw_balances[msg.sender] * time_between_raffles;

        user_to_old_balance[msg.sender] = updated_balance;
        user_to_new_balance[msg.sender] = next_balance;

        if (is_user_already_in_next_epoch_array[msg.sender] == false) {
            next_epoch_balance_instructions.push(msg.sender);
        }

        total_time_weighted_balance += time_until_next_raffle * amount;
    }

    modifier subtractRaffleBalance(uint256 amount) {
        // declare time_between_raffles in memory in two functions to save gas
        uint256 time_between_raffles = 604800;
        uint256 time_until_next_raffle = (time_between_raffles -
            (block.timestamp - last_raffle_time));
        uint256 updated_balance = time_until_next_raffle * amount;

        raw_balances[msg.sender] -= amount;

        // creates node in sortition tree for time weighted odds of user
        sortition_sum_trees.set(
            TREE_KEY,
            updated_balance,
            bytes32(uint256(uint160(msg.sender)))
        );

        _;

        uint256 next_balance = raw_balances[msg.sender] * time_between_raffles;

        user_to_old_balance[msg.sender] = updated_balance;
        user_to_new_balance[msg.sender] = next_balance;

        //if user is not already in list then add them
        if (is_user_already_in_next_epoch_array[msg.sender] == false) {
            next_epoch_balance_instructions.push(msg.sender);
        }

        total_time_weighted_balance -= time_until_next_raffle * amount;
    }

    function Deposit(uint256 amount) public payable addRaffleBalance(amount) {
        require(amount > 0, "Cannot stake 0");
        require(gaming_test_token.balanceOf(msg.sender) >= amount);

        // approval required on front end
        bool sent = gaming_test_token.transferFrom(
            msg.sender,
            address(this),
            amount
        );
        require(sent, "Failed to transfer tokens from user to vendor");

        total_token_entered += amount;

        emit depositMade(msg.sender, amount, total_token_entered);
    }

    function Withdraw(uint256 amount)
        public
        payable
        subtractRaffleBalance(amount)
    {
        require(amount > 0, "Cannot withdraw 0");
        require(
            raw_balances[msg.sender] >= amount,
            "Cannot withdraw more than you own"
        );

        bool withdrawn = gaming_test_token.transfer(msg.sender, amount);
        require(withdrawn, "Failed to withdraw tokens from contract to user");

        total_token_entered -= amount;

        emit withdrawMade(msg.sender, amount, total_token_entered);
    }

    function vaultNFT(IERC721 nft_contract_address, uint256 token_id) public {
        require(
            _address_whitelist[msg.sender],
            "Address not whitelisted to contribute NFTS, to whitelist your address reach out to Joe"
        );
        require(
            _nft_whitelist[nft_contract_address],
            "This NFT type is not whitelisted currently, to add your NFT reach out to Joe"
        );

        IERC721 nft_contract = nft_contract_address;
        // here we need to request and send approval to transfer token
        nft_contract.transferFrom(msg.sender, address(this), token_id);

        NFT memory new_nft = NFT({
            nft_contract: nft_contract,
            token_id: token_id
        });
        vaultedNFTs.push(new_nft);

        //tracking
        uint256 index = vaultedNFTs.length - 1;
        is_NFT_in_vault[nft_contract][token_id] = true;
        index_of_nft_in_array[nft_contract][token_id] = index;

        emit NFTVaulted(msg.sender, nft_contract_address, token_id);
    }

    modifier isWinner() {
        require(msg.sender == most_recent_raffle_winner);
        _;
    }

    modifier prizeUnclaimed() {
        require(
            is_NFT_in_vault[most_recent_prize.nft_contract][
                most_recent_prize.token_id
            ],
            "prize already claimed"
        );
        _;
    }

    modifier removeNFTFromArray() {
        _;
        uint256 index = index_of_nft_in_array[most_recent_prize.nft_contract][
            most_recent_prize.token_id
        ];
        uint256 last_index = vaultedNFTs.length - 1;

        vaultedNFTs[index] = vaultedNFTs[last_index];
        vaultedNFTs.pop();
        is_NFT_in_vault[most_recent_prize.nft_contract][
            most_recent_prize.token_id
        ] = false;
    }

    function claimPrize() external isWinner prizeUnclaimed removeNFTFromArray {
        _sendNFTFromVault(
            most_recent_prize.nft_contract,
            most_recent_prize.token_id,
            msg.sender
        );
    }

    //make claimable so they have to pay the gas
    function _sendNFTFromVault(
        IERC721 nft_contract_address,
        uint256 token_id,
        address nft_recipient
    ) internal {
        IERC721 nft_contract = nft_contract_address;
        nft_contract.approve(nft_recipient, token_id);
        nft_contract.transferFrom(address(this), nft_recipient, token_id);

        emit NFTsent(nft_recipient, nft_contract_address, token_id);
    }

    function initiateRaffle() external returns (bytes32) {
        require(vaultedNFTs.length > 0, "no NFTs to raffle");

        current_random_request_id = gamedrop_vrf_contract.getRandomNumber();

        emit raffleInitiated(
            block.timestamp,
            current_random_request_id,
            msg.sender
        );

        return current_random_request_id;
    }

    modifier _updateBalancesAfterRaffle() {
        _;

        uint256 x;

        for (x = 0; x < next_epoch_balance_instructions.length; x++) {
            address user = next_epoch_balance_instructions[x];
            uint256 next_balance = user_to_new_balance[user];

            sortition_sum_trees.set(
                TREE_KEY,
                next_balance,
                bytes32(uint256(uint160(user)))
            );

            uint256 old_balance = user_to_old_balance[user];
            total_time_weighted_balance += next_balance - old_balance;
        }

        delete next_epoch_balance_instructions;
    }

    function _chooseWinner(uint256 random_number) internal returns (address) {
        //set range for the uniform random number
        uint256 bound = total_time_weighted_balance;
        address selected;

        if (bound == 0) {
            selected = address(0);
        } else {
            uint256 number = UniformRandomNumber.uniform(random_number, bound);
            selected = address(
                (uint160(uint256(sortition_sum_trees.draw(TREE_KEY, number))))
            );
        }
        return selected;
    }

    function _chooseNFT(uint256 random_number) internal returns (NFT memory) {
        uint256 bound = vaultedNFTs.length;
        uint256 index_of_nft;

        index_of_nft = UniformRandomNumber.uniform(random_number, bound);

        return vaultedNFTs[index_of_nft];
    }

    function completeRaffle(uint256 random_number)
        external
        _updateBalancesAfterRaffle
    {
        //updating these two variables makes the prize claimable by the winner
        most_recent_raffle_winner = _chooseWinner(random_number);
        most_recent_prize = _chooseNFT(random_number);

        emit raffleCompleted(
            block.timestamp,
            most_recent_raffle_winner,
            most_recent_prize
        );
    }

    function updateGamedropVRFContract(IGVRF new_vrf_contract)
        public
        onlyOwner
    {
        gamedrop_vrf_contract = new_vrf_contract;
    }

    function addAddressToWhitelist(address whitelist_address) public onlyOwner {
        _address_whitelist[whitelist_address] = true;

        emit AddressWhitelist(whitelist_address);
    }

    function addNFTToWhitelist(IERC721 nft_whitelist_address) public {
        require(msg.sender == owner(), "sender not owner");
        _nft_whitelist[nft_whitelist_address] = true;

        emit NFTWhitelist(nft_whitelist_address);
    }

    function view_raw_balance(address wallet_address)
        public
        view
        returns (uint256)
    {
        return raw_balances[wallet_address];
    }

    function is_address_whitelisted(address wallet_address)
        public
        view
        returns (bool)
    {
        return _address_whitelist[wallet_address];
    }

    function is_nft_whitelisted(IERC721 nft_contract)
        public
        view
        returns (bool)
    {
        return _nft_whitelist[nft_contract];
    }

    function view_odds_of_winning(address user) public view returns (uint256) {
        return
            sortition_sum_trees.stakeOf(
                TREE_KEY,
                bytes32(uint256(uint160(user)))
            );
    }

    function get_total_number_of_NFTS() public view returns (uint256) {
        return vaultedNFTs.length;
    }

    function check_if_NFT_in_vault(IERC721 nft_contract, uint256 token_id)
        public
        view
        returns (bool)
    {
        return is_NFT_in_vault[nft_contract][token_id];
    }
}
