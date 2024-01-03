pragma solidity ^0.5.15;

library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        
        
        
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        
        require(b > 0, errorMessage);
        uint256 c = a / b;
        

        return c;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Context {
    
    
    constructor () internal { }
    

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    
    using SafeMath for uint256;
    
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    
    function owner() public view returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract PZSConfig is Ownable{
    
    struct Stage {
        
        uint256 minimum;
        
        uint256 maximum;
        
        uint256 period;
        
        uint256 scale;
        
        uint256 totalSuply;
        
        uint256 startTime;
        
        //Super node purchase amount
        uint256 partnerBecome;
        
    }
    
    Stage[3] stages;
    
    function getStage(uint8 version) external view returns(uint256 minimum,uint256 maximum,uint256 period,uint256 scale,uint256 totalSuply,uint256 startTime,uint256 partnerBecome) {
        
        Stage memory stage = stages[version];
        
        return (stage.minimum,stage.maximum,stage.period,stage.scale,stage.totalSuply,stage.startTime,stage.partnerBecome);
    }
    
    function setStage(uint8 version,uint256 minimum,uint256 maximum,uint256 period,uint256 scale,uint256 totalSuply,uint256 startTime,uint256 partnerBecome) external onlyOwner returns (bool) {
        Stage memory stage = Stage({
            minimum: minimum,
            maximum: maximum,
            period: period,
            scale: scale,
            totalSuply: totalSuply,
            startTime: startTime,
            partnerBecome: partnerBecome
        });
        stages[version] = stage;
        return true;
    }
    
    function partnerBecome(uint8 version) external view returns(uint256){
        return stages[version].partnerBecome;
    }
    
    
    function checkStart(uint8 version) public view returns(bool){
        Stage memory stage = stages[version];
        return stage.startTime<now&&stage.startTime.add(stage.period)>now;
    }
    
    function underway() external view returns(uint8){
        
        for(uint8 version = 0;version<3;version++){
            if(checkStart(version)){
                return version;
            }
        }
        return uint8(-1);
        
    }
    
}