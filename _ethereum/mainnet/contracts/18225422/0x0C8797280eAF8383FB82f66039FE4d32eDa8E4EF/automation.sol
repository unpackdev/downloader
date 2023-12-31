import "./IERC20.sol";

contract automation{
    constructor(){}

    receive() external payable{}
    fallback() external payable{}
    bytes32[40] private gap;
    address public owner;
    address public operator;

    function initialize() external{
        address _owner = owner;
        require(_owner == address(0) || _owner == msg.sender, "failed initialize");
        if( _owner != msg.sender) _transferOwnership(msg.sender);

    }

    modifier onlyOwner(){
        require(owner == msg.sender, "access denied. owner ONLY.");
        _;
    }

    function setOperator(address _operator) external onlyOwner{
        operator = _operator;
    }

    function transferOwnership(address _to) external onlyOwner{
        _transferOwnership(_to);
    }

    function performUpkeep(bytes calldata _performData) external payable{
        (address target, bytes memory payload, bool delegateCall) = abi.decode(_performData, (address, bytes, bool));
        bool success;
        bytes memory data;
        if( delegateCall == true ){
            require(operator == msg.sender || owner == msg.sender, "operator or owner ONLY");
            (success, data) = target.delegatecall(payload);
        }
        else{
            (success, data) = target.staticcall(abi.encodeWithSignature("owner()"));
            require(success == true && abi.decode(data, (address)) == owner, "owner contract ONLY");
            (success, data) = target.call(payload);
        }
        if( success == false ){
            assembly{data:= add(data, 4)}
            revert(abi.decode(data, (string)));
        }
    }

    function checkUpkeep(bytes calldata _checkData) external view returns(bool upKeepNeeded, bytes memory performData){
        (address target, bytes memory payload) = abi.decode(_checkData, (address, bytes));
        (bool success, bytes memory data) = target.staticcall(payload);
        require(success == true, "failed to call function");
        (upKeepNeeded, performData) = abi.decode(data, (bool, bytes));
    }

    function sweep(IERC20[] memory tokens, uint256[] memory amounts) external{
        uint256 length = tokens.length;
        address _owner = owner;
        for(uint256 i=0; i<length; i++){tokens[i].transfer(_owner, amounts[i]);}
    }

    function _transferOwnership(address _to) internal{
        owner = _to;
    }
}
