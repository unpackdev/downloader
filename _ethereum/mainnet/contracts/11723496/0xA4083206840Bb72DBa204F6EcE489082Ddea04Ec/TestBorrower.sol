pragma solidity ^0.6.0;


interface LiquidityPool {
    function borrow(
        address _token,
        uint256 _amount,
        bytes calldata _data
    ) external;
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IDistributor {
    function claim(address _to, uint256 _earningsToDate, uint256 _nonce, bytes memory _signature) external;
}

contract TestBorrower {
    address payable immutable owner;

    address constant borrowProxy = 0x82151CA501c81108d032C490E25f804787BEF3b8;

    address payable constant liquidityPool = 0x53463cd0b074E5FDafc55DcE7B1C82ADF1a43B2E;
    
    IDistributor constant distributor = IDistributor(0xF55A73a366F1F9F03CEf4cc10D3cD21e5c6A9026);
    
    address constant rook = 0xfA5047c9c78B8877af97BDcb85Db743fD7313d4a;

    modifier onlyOwner {
        require(msg.sender == owner, "NOT OWNER");
        _;
    }

    modifier onlyBorrowProxy {
        require(msg.sender == borrowProxy, "NOT BORROW PROXY");
        _;
    }
    
    constructor() public payable {
        owner = msg.sender;
    }

    function doBorrow(address[] memory tokens) external payable onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            LiquidityPool(liquidityPool).borrow(
                token,
                1,
                abi.encodeWithSelector(
                    this.borrowCallback.selector,
                    token
                )
            );
        }
    }
    
    function borrowCallback(address token) external onlyBorrowProxy {
        if (token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            (bool success, bytes memory retData) = liquidityPool.call{ value: address(this).balance }("");
            require(success, string(retData));
        } else {
            uint256 balance = IERC20(token).balanceOf(address(this));
            require(IERC20(token).transfer(liquidityPool, balance), "ERC20 error");
        }
    }
    
    function claim(address _to, uint256 _earningsToDate, uint256 _nonce, bytes memory _signature) external {
        distributor.claim(_to, _earningsToDate, _nonce, _signature);
        withdrawTokens(rook);
    }
    
    function withdrawTokens(address token) public {
        if (token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            owner.transfer(address(this).balance);
        } else {
            uint256 balance = IERC20(token).balanceOf(address(this));
            require(IERC20(token).transfer(owner, balance), "ERC20 error");
        }
    }
    
    function delegateCall(address to, bytes memory data) external payable onlyOwner {
        (bool success, bytes memory retData) = to.delegatecall(data);
        require(success, string(retData));
    }
    
    fallback() external payable { return; }
}