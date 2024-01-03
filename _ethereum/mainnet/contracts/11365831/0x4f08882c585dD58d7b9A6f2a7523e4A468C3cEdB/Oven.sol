// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./AccessControl.sol";
import "./PieRecipe.sol";

contract Oven is AccessControl {
    using SafeMath for uint256;

    event Deposit(address user, uint256 amount);
    event WithdrawETH(address user, uint256 amount, address receiver);
    event WithdrawOuput(address user, uint256 amount, address receiver);
    event Bake(address user, uint256 amount, uint256 price);

    // uses the default admin role
    bytes32 constant public CONTROLLER_ROLE = DEFAULT_ADMIN_ROLE;
    bytes32 constant public CAP_SETTER_ROLE = keccak256(abi.encode("CAP_SETTER"));
    bytes32 constant public BAKER_ROLE = keccak256(abi.encode("BAKER"));

    // Agent controlled by Pie-Crust voting app
    address payable constant public TOKEN_SAFE = 0xAF2fE0d4fe879066B2BaA68d9e56cC375DF22815;

    mapping(address => uint256) public ethBalanceOf;
    mapping(address => uint256) public outputBalanceOf;

    IERC20 public pie;
    PieRecipe public recipe;
    uint256 public cap;

    constructor(
        address _controller,
        address _capSetter,
        address _baker,
        address _pie,
        address _recipe
    ) public {
        _setupRole(CONTROLLER_ROLE, _controller);
        _setupRole(CAP_SETTER_ROLE, _capSetter);
        _setupRole(BAKER_ROLE, _baker);
        pie = IERC20(_pie);
        recipe = PieRecipe(_recipe);
    }

    modifier ovenIsReady {
        require(address(pie) != address(0), "PIE_NOT_SET");
        require(address(recipe) != address(0), "RECIPE_NOT_SET");
        _;
    }

    modifier onlyRole(bytes32 _role) {
        require(hasRole(_role, msg.sender), "AUTH_FAILED");
        _;
    }

    // _maxprice should be equal to the sum of _receivers.
    // this variable is needed because in the time between calling this function
    // and execution, the _receiver amounts can differ.
    function bake(
        address[] calldata _receivers,
        uint256 _outputAmount,
        uint256 _maxPrice
    ) public ovenIsReady onlyRole(BAKER_ROLE) {
        uint256 realPrice = recipe.calcToPie(address(pie), _outputAmount);
        require(realPrice <= _maxPrice, "PRICE_ERROR");

        uint256 totalInputAmount = 0;
        for (uint256 i = 0; i < _receivers.length; i++) {
            // This logic aims to execute the following logic
            // E.g. 5 eth is needed to mint the outputAmount
            // User 1: 2 eth (100% used)
            // User 2: 2 eth (100% used)
            // User 3: 2 eth (50% used)
            // User 4: 2 eth (0% used)

            uint256 userAmount = ethBalanceOf[_receivers[i]];
            if (totalInputAmount == realPrice) {
                break;
            } else if (totalInputAmount.add(userAmount) <= realPrice) {
                totalInputAmount = totalInputAmount.add(userAmount);
            } else {
                userAmount = realPrice.sub(totalInputAmount);
                // e.g. totalInputAmount = realPrice
                totalInputAmount = totalInputAmount.add(userAmount);
            }

            ethBalanceOf[_receivers[i]] = ethBalanceOf[_receivers[i]].sub(
                userAmount
            );

            uint256 userBakeAmount = _outputAmount.mul(userAmount).div(
                realPrice
            );
            outputBalanceOf[_receivers[i]] = outputBalanceOf[_receivers[i]].add(
                userBakeAmount
            );

            emit Bake(_receivers[i], userBakeAmount, userAmount);
        }
        // Provided balances are too low.
        require(totalInputAmount == realPrice, "INSUFFICIENT_FUNDS");
        recipe.toPie{value: realPrice}(address(pie), _outputAmount);
    }

    function deposit() public payable ovenIsReady {
        ethBalanceOf[msg.sender] = ethBalanceOf[msg.sender].add(msg.value);
        require(address(this).balance <= cap, "MAX_CAP");
        emit Deposit(msg.sender, msg.value);
    }

    receive() external payable {
        deposit();
    }

    function withdrawAll(address payable _receiver) external ovenIsReady {
        withdrawAllETH(_receiver);
        withdrawOutput(_receiver);
    }

    function withdrawAllETH(address payable _receiver) public ovenIsReady {
        withdrawETH(ethBalanceOf[msg.sender], _receiver);
    }

    function withdrawETH(uint256 _amount, address payable _receiver)
        public
        ovenIsReady
    {
        ethBalanceOf[msg.sender] = ethBalanceOf[msg.sender].sub(_amount);
        _receiver.transfer(_amount);
        emit WithdrawETH(msg.sender, _amount, _receiver);
    }

    function withdrawOutput(address _receiver) public ovenIsReady {
        uint256 _amount = outputBalanceOf[msg.sender];
        outputBalanceOf[msg.sender] = 0;
        pie.transfer(_receiver, _amount);
        emit WithdrawOuput(msg.sender, _amount, _receiver);
    }

    function setCap(uint256 _cap) external onlyRole(CAP_SETTER_ROLE) {
        cap = _cap;
    }

    function setPie(address _pie) public onlyRole(CONTROLLER_ROLE) {
        // Only able to change pie from address(0) to an actual address
        // Otherwise old outputBalances can conflict with a new pie
        require(address(pie) == address(0), "PIE_ALREADY_SET");
        pie = IERC20(_pie);
    }

    function setRecipe(address _recipe) public onlyRole(CONTROLLER_ROLE) {
        // Only able to change pie from address(0) to an actual address
        // Otherwise old outputBalances can conflict with a new pie
        require(address(recipe) == address(0), "RECIPE_ALREADY_SET");
        recipe = PieRecipe(_recipe);
    }

    function setPieAndRecipe(address _pie, address _recipe) external {
        setPie(_pie);
        setRecipe(_recipe);
    }

    function getCap() external view returns (uint256) {
        return cap;
    }

    function saveToken(address _token) external onlyRole(CONTROLLER_ROLE) {
        IERC20 token = IERC20(_token);

        token.transfer(
            TOKEN_SAFE,
            token.balanceOf(address(this))
        );
    }

    function saveETH() external onlyRole(CONTROLLER_ROLE) {
        TOKEN_SAFE.transfer(address(this).balance);
    }
}
