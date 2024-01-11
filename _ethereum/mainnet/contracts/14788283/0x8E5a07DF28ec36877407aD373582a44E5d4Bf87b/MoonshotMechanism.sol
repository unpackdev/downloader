
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./SafeMath.sol";
import "./ERC20.sol";
import "./IPYESwapRouter.sol";
import "./IMoonshotMechanism.sol";
import "./IStakingContract.sol";

contract MoonshotMechanism is IMoonshotMechanism {
    using SafeMath for uint256;

    address public _token;
    IStakingContract public StakingContract;
    address public stakingContract;

    struct Moonshot {
        string Name;
        uint Value;
    }

    bool public initialized = true;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    Moonshot[] internal Moonshots;
    address admin;
    uint public disbursalThreshold;
    uint public lastMoonShot;
    bool public autoMoonshotEnabled;

    bool private inSwap;

    modifier swapping() { inSwap = true; _; inSwap = false; }
    IPYESwapRouter public pyeSwapRouter;
    address public WETH;

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor() {
        pyeSwapRouter = IPYESwapRouter(0x4F71E29C3D5934A15308005B19Ca263061E99616);
        WETH = pyeSwapRouter.WETH();
        _token = msg.sender;

        admin = 0x5f46913071f854A99FeB5B3cF54851E539CA6D44;
        Moonshots.push(Moonshot("Waxing", 1000));
        Moonshots.push(Moonshot("Waning", 2500));
        Moonshots.push(Moonshot("Half Moon", 3750));
        Moonshots.push(Moonshot("Full Moon", 5000));
        Moonshots.push(Moonshot("Blue Moon", 10000));
        autoMoonshotEnabled = false;
        disbursalThreshold = 1*10**6;
    }

    modifier onlyAdmin {
        require(msg.sender == admin , "You are not the admin");
        _;
    }

    modifier onlyAdminOrToken {
        require(msg.sender == admin || msg.sender == _token);
        _;
    }
    //-------------------------- BEGIN EDITING FUNCTIONS ----------------------------------

    // Allows admin to create a new moonshot with a corresponding value; pushes new moonshot to end of array and increases array length by 1.
    function createMoonshot(string memory _newName, uint _newValue) public onlyAdmin {
        Moonshots.push(Moonshot(_newName, _newValue));
    }
    // Remove last element from array; this will decrease the array length by 1.
    function popMoonshot() public onlyAdmin {
        Moonshots.pop();
    }
    // User enters the value of the moonshot to delete, not the index. EX: enter 2000 to delete the Blue Moon struct, the array length is then decreased by 1.
        // moves the struct you want to delete to the end of the array, deletes it, and then pops the array to avoid empty arrays being selected by pickMoonshot.
    function deleteMoonshot(uint _value) public onlyAdmin {
        uint moonshotLength = Moonshots.length;
        for(uint i = 0; i < moonshotLength; i++) {
            if (_value == Moonshots[i].Value) {
                if (1 < Moonshots.length && i < moonshotLength-1) {
                    Moonshots[i] = Moonshots[moonshotLength-1]; }
                    delete Moonshots[moonshotLength-1];
                    Moonshots.pop();
                    break;
            }
        }
    }
    function updateAdmin(address _newAdmin) public onlyAdmin {
        admin = _newAdmin;
    }

    function updateRouterAndPair(address _router) public onlyAdmin {	
        pyeSwapRouter = IPYESwapRouter(_router);	
    }

    function getGoal() external view override returns(uint256){
        return disbursalThreshold;
    }

    function getMoonshotBalance() external view override returns(uint256){
        return IERC20(address(WETH)).balanceOf(address(this));
    }

    //-------------------------- BEGIN GETTER FUNCTIONS ----------------------------------
    // Enter an index to return the name and value of the moonshot @ that index in the Moonshots array.
    function getMoonshotNameAndValue(uint _index) public view returns (string memory, uint) {
        return (Moonshots[_index].Name, Moonshots[_index].Value);
    }
    // Returns the value of the contract in ETH.
    function getContractValue() public view onlyAdmin returns (uint) {
        return address(this).balance;
    }
    // Getter fxn to see the disbursal threshold value.
    function getDisbursalValue() public view onlyAdmin returns (uint) {
        return disbursalThreshold;
    }
    //-------------------------- BEGIN MOONSHOT SELECTION FUNCTIONS ----------------------------------
    // Generates a "random" number.
    function random() internal view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty + block.timestamp)));
    }

    // Allows admin to manually select a new disbursal threshold.
    function overrideDisbursalThreshold(uint newDisbursalThreshold) public onlyAdmin returns (uint) {
        disbursalThreshold = newDisbursalThreshold;
        return disbursalThreshold;
    }

    function pickMoonshot() internal {
        require(Moonshots.length > 1, "The Moonshot array has only one moonshot, please create a new Moonshot!");
        Moonshot storage winningStruct = Moonshots[random() % Moonshots.length];
        uint disbursalValue = winningStruct.Value;
        lastMoonShot = disbursalThreshold;
        
        // @todo update decimals for mainnet
        disbursalThreshold = disbursalValue * 10**13;
    }
  
    function shouldLaunchMoon(address from, address to) external view override returns (bool) {
        return (IERC20(address(WETH)).balanceOf(address(this)) >= disbursalThreshold 
            && disbursalThreshold != 0 
            && from != address(this) 
            && to != address(this) 
            && autoMoonshotEnabled); 
    }

    // calling pickMoonshot() required becasue upon contract deployment disbursalThreshold is initialized to 0
    function launchMoonshot() external onlyAdminOrToken override {
        if (IERC20(address(WETH)).balanceOf(address(this)) >= disbursalThreshold && disbursalThreshold != 0) { 
            buyReflectTokens(disbursalThreshold, address(this)); 
        } 
    }

    function buyReflectTokens(uint256 amount, address to) internal {
        
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = _token;

        IERC20(WETH).approve(address(pyeSwapRouter), amount);

        pyeSwapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            to,
            block.timestamp + 10 minutes
        );

        sendMFToStakingContractAfterBuyReflectTokens(stakingContract, IERC20(_token).balanceOf(address(this)));
        pickMoonshot();
    }

    function sendMFToStakingContractAfterBuyReflectTokens(address _stakingContract, uint256 _amountMF) internal {
        require(_stakingContract != address(0), "The staking contract address has not been set yet.");
        require(_amountMF > 0 , "You cannot send 0 tokens!");
        IERC20(_token).transfer(_stakingContract, _amountMF);
        StakingContract.depositMFToStakingContract(_amountMF);
    }

    function setStakingContractAddress(address _newStakingContractAddress) public onlyAdmin {
        stakingContract = _newStakingContractAddress; 
        StakingContract = IStakingContract(_newStakingContractAddress);

        IERC20(_token).approve(address(_newStakingContractAddress), 1 * 10**6 * 10**18);
    }

    function swapToWETH(address token) public onlyAdmin {
        uint256 amount = IERC20(address(token)).balanceOf(address(this));
        address[] memory path = new address[](2);
            path[0] = token;
            path[1] = WETH;

            IERC20(token).approve(address(pyeSwapRouter), amount);

            pyeSwapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amount,
                0,
                path,
                address(this),
                block.timestamp + 10 minutes
            );
    }

    function enableAutoMoonshot(bool _enabled) external onlyAdmin {
        autoMoonshotEnabled = _enabled;
    }

    function approveStakingContract(uint256 amount) external onlyAdmin {
        IERC20(_token).approve(address(stakingContract), amount);
    }

    // Rescue eth that is sent here by mistake
    function rescueETH(uint256 amount, address to) external onlyAdmin{
        payable(to).transfer(amount);
      }

    // Rescue tokens that are sent here by mistake
    function rescueToken(IERC20 token, uint256 amount, address to) external onlyAdmin {
        if( token.balanceOf(address(this)) < amount ) {
            amount = token.balanceOf(address(this));
        }
        token.transfer(to, amount);
    }
}
