pragma solidity ^0.5.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public returns (bytes4);
}

interface IRAYStorage {
    function getContractAddress(bytes32 contractId) external view returns (address);
    function getPrincipalAddress(bytes32 portfolioId) external view returns (address);
}

interface IRAYPortfolioManager {
    function mint(bytes32 portfolioId, address beneficiary, uint256 value) external payable returns(bytes32);
    function deposit(bytes32 tokenId, uint256 value) external payable;
    function redeem(bytes32 tokenId, uint256 valueToWithdraw, address originalCaller) external returns(uint256);
}

interface IRAYNAVCalculator {
    function getTokenValue(bytes32 portfolioId, bytes32 tokenId) external view returns(uint256, uint256);
}

contract RAYDaiCompoundTest is IERC721Receiver {
    bytes32 internal constant RAY_PORTFOLIO_MANAGER_CONTRACT = keccak256("PortfolioManagerContract");
    bytes32 internal constant RAY_NAV_CALCULATOR_CONTRACT = keccak256("NAVCalculatorContract");
    bytes32 internal constant RAY_TOKEN_CONTRACT = keccak256("RAYTokenContract");
    bytes32 public constant   RAY_PORTFOLIO_ID = keccak256("DaiCompound");

    IRAYStorage public rayStorage;
    bytes32 public rayTokenId;

    constructor(address rayStorageAddress) public {
        rayStorage = IRAYStorage(rayStorageAddress);
    }

    function onERC721Received(address, address, uint256, bytes memory) public returns (bytes4) {
        address rayTokenContract = rayStorage.getContractAddress(RAY_TOKEN_CONTRACT);
        require(msg.sender == rayTokenContract, "Only accept RAY Token transfers");
        return this.onERC721Received.selector;
    }

    function deposit(uint256 amount) public {
        IERC20 token = IERC20(rayStorage.getPrincipalAddress(RAY_PORTFOLIO_ID));
        IRAYPortfolioManager pm = rayPortfolioManager();
        token.transferFrom(msg.sender, address(this), amount);
        token.approve(address(pm), amount);
        if (rayTokenId == 0x0) {
            rayTokenId = pm.mint(RAY_PORTFOLIO_ID, address(this), amount);
        } else {
            pm.deposit(rayTokenId, amount);
        }
    }
    
    function withdraw(uint256 amount) public {
        require(rayTokenId != 0x0, "RAY token not minted");
        IERC20 token = IERC20(rayStorage.getPrincipalAddress(RAY_PORTFOLIO_ID));
        IRAYPortfolioManager pm = rayPortfolioManager();
        uint256 withdrawn = pm.redeem(rayTokenId, amount, address(0));
        token.transfer(msg.sender, withdrawn);
    }
    
    function withdrawHalf() public {
        uint256 amount = balance()/2;
        withdraw(amount);
    }

    function balance() public view returns(uint256){
        if (rayTokenId == 0x0) return 0;
        (uint256 amount,) = rayNAVCalculator().getTokenValue(RAY_PORTFOLIO_ID, rayTokenId);
        return amount;
    }

    function rayPortfolioManager() private view returns(IRAYPortfolioManager){
        return IRAYPortfolioManager(rayStorage.getContractAddress(RAY_PORTFOLIO_MANAGER_CONTRACT));
    }

    function rayNAVCalculator() private view returns(IRAYNAVCalculator){
        return IRAYNAVCalculator(rayStorage.getContractAddress(RAY_NAV_CALCULATOR_CONTRACT));
    }

}