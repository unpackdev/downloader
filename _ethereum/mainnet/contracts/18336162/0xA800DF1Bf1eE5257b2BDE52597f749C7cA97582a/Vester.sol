// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

contract Vester {
    uint256 public vestingTime;
    address public esembr;

    uint256 multiplier;
    uint256 public precision = 1e9;

    mapping (address => uint256) public entryTimes; // timestamp the user started vesting
    mapping (address => uint256) public lastClaim; // timestamp the user last claimed their vested tokens
    mapping (address => uint256) public vestingAmount; // stays constant throughout the entire vesting process.

    constructor(uint256 timeframe, uint256 _multiplier, address _esembr){
        require(timeframe > 0, "Timeframe cannot be 0");
		require(multiplier <= 10_000, "Multiplier too high");

        vestingTime = timeframe;
        multiplier = _multiplier;
        esembr = _esembr;
    }

    modifier onlyEsEMBR() {
        require(msg.sender == esembr, "Vester: Only esEMBR contract can call this function");
        _;
    }

    // This function is only called by esEMBR contract. esEMBR also calls claim for this user.
    // **claim() MUST be called by esEMBR and handled correctly before calling vest()**
    function vest(address user, uint256 amount) onlyEsEMBR external {
        require(amount >= precision, "Vester: Amount cant be smaller than 1,000,000,000");

        if (vestingAmount[user] != 0) {
            // claim then revest
            uint256 time_left = (entryTimes[user] + vestingTime - lastClaim[user]) * precision;
            uint256 pct_to_claim = time_left / vestingTime;
            uint256 amount_left_unvested = pct_to_claim * vestingAmount[user] / precision;

            amount += amount_left_unvested;
        }

        vestingAmount[user] = amount;
        entryTimes[user] = block.timestamp;
        lastClaim[user] = block.timestamp;
    }

    function claim(address user) onlyEsEMBR public returns (uint256) {
        (uint256 claimable_amount, uint256 entry_time) = claimable(user);
        if (claimable_amount == 0) return 0;

        if (block.timestamp > entry_time + vestingTime) {
            // User fully claimed all the vested tokens, delete all related records from storage
            delete vestingAmount[user];
            delete entryTimes[user];
            delete lastClaim[user];
        } else {
            lastClaim[user] = block.timestamp;
        }

        return (claimable_amount * multiplier) / 10000;
    }

    function claimable(address user) public view returns (uint256 /* claimable amount */, uint256 /* entry time */) {
        if (vestingAmount[user] == 0) return (0, 0);

        uint256 entry_time = entryTimes[user];
        uint256 last_claim_time = lastClaim[user];

        uint256 time_to_claim = 0;
        if (block.timestamp > entry_time + vestingTime) {
            time_to_claim = (entry_time + vestingTime - last_claim_time) * precision;
        } else {
            time_to_claim = (block.timestamp - last_claim_time) * precision;
        }

        uint256 pct_to_claim = time_to_claim / vestingTime;

        return ((pct_to_claim * vestingAmount[user] / precision), entry_time);
    }
}
