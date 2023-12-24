// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

contract Contribution {

    // roles
    address public immutable owner;
    address payable public immutable beneficiary;

    // countdown and threshold
    bool public materialReleaseConditionMet = false;
    uint256 public deadline;
    uint256 public countdownPeriod;
    uint256 public threshold;
    uint256 public minContribution;
    uint256 public initialWindow;  // TODO: Constant?

    // commit and reveal
    bool public isKeySet = false;
    bytes32 public keyPlaintextHash;
    bytes public keyCiphertext;
    bytes public keyPlaintext;

    // testnet mode
    bool public testnet;

    // contributions storage
    bool[] public contributionIsCombined;
    uint256[] public contributionAmounts;
    uint256[] public contributionDatetimes;
    address[] public contributorsForEachContribution;

    address public artifactContract;

    //events
    event Contribute(address indexed contributor, uint256 amount);
    event Decryptable(address indexed lastContributor);
    event Withdraw(address indexed beneficiary, uint256 amount);
    event ClockReset(uint256 deadline);

    constructor(
        uint256 _countdownPeriod,
        uint256 _threshold,
        uint256 _minContribution,
        uint256 _initialWindow,
        address payable _beneficiary,
        bool _testnet
    ) {
        countdownPeriod = _countdownPeriod;
        deadline = 0;
        owner = msg.sender;
        beneficiary = payable(_beneficiary);
        threshold = _threshold;
        minContribution = _minContribution;
        testnet = _testnet;
        initialWindow = _initialWindow;  // 2 weeks
    }

    modifier onlyOwner() {
        require(msg.sender == owner,
            "Only the contract owner can call this function.");
        _;
    }

    modifier onlyBeneficiary() {
        require(
            msg.sender == beneficiary,
            "Only the beneficiary can call this function."
        );
        _;
    }

    //
    // Testnet functions
    //

    function resetClock() external onlyOwner {
        require(testnet, "This function is only available on testnet.");
        deadline = block.timestamp + countdownPeriod;
    }

    function setMaterialReleaseConditionMet(bool status) external onlyOwner {
        require(testnet, "This function is only available on testnet.");
        materialReleaseConditionMet = status;
    }

    function setThreshold(uint256 _threshold) external onlyOwner {
        require(testnet, "This function is only available on testnet.");
        threshold = _threshold;
    }

    //
    // Production functions
    //

    function setArtifactContract(address _artifactContract) public onlyOwner {
        artifactContract = _artifactContract;
    }

    function commitSecret(bytes32 _hash, bytes memory _ciphertext) external onlyOwner {
        if (!testnet) {
            require(!isKeySet, "Key already set.");
        }
        keyPlaintextHash = _hash;
        keyCiphertext = _ciphertext;
        isKeySet = true;
        deadline = block.timestamp + initialWindow; // The initial window begins now and lasts initialWindow seconds.
    }

    function revealSecret(bytes memory secret) external {
        require(materialReleaseConditionMet, "Material has not been set for a release.");
        require(keccak256(secret) == keyPlaintextHash, "Invalid secret provided, hash does not match.");
        keyPlaintext = secret;
    }

    function _contribute(bool combine) internal {
        require(isKeySet, "Material is not ready for contributions yet.");
        require(!materialReleaseConditionMet || block.timestamp < deadline,
            "Cannot contribute after the deadline");
        require(msg.value >= minContribution,
            "Contribution must be equal to or greater than the minimum.");

        contributionAmounts.push(msg.value);
        contributorsForEachContribution.push(msg.sender);
        contributionIsCombined.push(combine);
        contributionDatetimes.push(block.timestamp);

        if (address(this).balance >= threshold && !materialReleaseConditionMet) {
            materialReleaseConditionMet = true;  // BOOM! Release the material!
            emit Decryptable(msg.sender);
        }

        if (materialReleaseConditionMet) {

            // If the deadline is within the countdownPeriod, extend it by countdownPeriod.
            if (deadline - block.timestamp < countdownPeriod) {
                deadline = block.timestamp + countdownPeriod;
                emit ClockReset(deadline);
            }

        }
        emit Contribute(msg.sender, msg.value);
    }

    function contribute() external payable {
        _contribute(false);
    }

    function contributeAndCombine() external payable {
        _contribute(true);
    }

    function totalContributedByAddress(address contributor) external view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < contributorsForEachContribution.length; i++) {
            if (contributorsForEachContribution[i] == contributor) {
                total += contributionAmounts[i];
            }
        }
        return total;
    }

    receive() external payable {
        emit Contribute(msg.sender, msg.value);
    }

    function getAllContributions() external view returns (address[] memory, uint256[] memory, bool[] memory, uint256[] memory) {

        return (contributorsForEachContribution, contributionAmounts, contributionIsCombined, contributionDatetimes);
    }

    function withdraw() external onlyBeneficiary {
        require(materialReleaseConditionMet, "Material has not been set for a release.");
        uint256 balance = address(this).balance;
        beneficiary.transfer(balance);
        emit Withdraw(beneficiary, balance);
    }

}
