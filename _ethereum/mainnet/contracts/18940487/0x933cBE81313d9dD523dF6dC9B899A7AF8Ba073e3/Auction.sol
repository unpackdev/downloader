// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

interface IERC20 {
    function transfer(address,uint) external returns (bool);
    function transferFrom(address,address,uint) external returns (bool);
    function balanceOf(address) external view returns (uint);
}

interface IDBR is IERC20 {
    function mint(address,uint) external;
}

interface ISaleHandler {
    function onReceive() external;
    function getCapacity() external view returns (uint);
}

contract Auction {

    address public gov;
    address public operator;
    IDBR public immutable dbr;
    IERC20 public immutable dola;
    ISaleHandler public saleHandler;
    uint public dolaReserve;
    uint public dbrReserve;
    uint public dbrRatePerYear;
    uint public maxDbrRatePerYear;
    uint public lastUpdate;
    
    constructor (
        address _gov,
        address _operator,
        address _dbr,
        address _dola,
        address handler,
        uint _dolaReserve,
        uint _dbrReserve
    ) {
        require(_dolaReserve > 0, "Dola reserve must be positive");
        require(_dbrReserve > 0, "DBR reserve must be positive");
        gov = _gov;
        operator = _operator;
        dbr = IDBR(_dbr);
        dola = IERC20(_dola);
        saleHandler = ISaleHandler(handler);
        dolaReserve = _dolaReserve;
        dbrReserve = _dbrReserve;
    }

    modifier updateReserves {
        (dolaReserve, dbrReserve) = getCurrentReserves();
        lastUpdate = block.timestamp;
        _;
    }

    modifier onlyGov {
        require(msg.sender == gov, "onlyGov");
        _;
    }

    modifier onlyGovOrOperator {
        require(msg.sender == operator || msg.sender == gov, "onlyGov");
        _;
    }

    function getCurrentReserves() public view returns (uint _dolaReserve, uint _dbrReserve) {
        uint timeElapsed = block.timestamp - lastUpdate;
        if(timeElapsed > 0) {
            uint K = dolaReserve * dbrReserve;
            uint DbrsIn = timeElapsed * dbrRatePerYear / 365 days;
            _dbrReserve = dbrReserve + DbrsIn;
            _dolaReserve = K / _dbrReserve;
        } else {
            _dolaReserve = dolaReserve;
            _dbrReserve = dbrReserve;
        }
    }

    function setGov(address _gov) external onlyGov { gov = _gov; }
    function setOperator(address _operator) external onlyGov { operator = _operator; }
    function setSaleHandler(address _saleHandler) external onlyGov { saleHandler = ISaleHandler(_saleHandler); }

    function setMaxDbrRatePerYear(uint _maxRate) external onlyGov updateReserves {
        maxDbrRatePerYear = _maxRate;
        emit MaxRateUpdate(_maxRate);
        if(dbrRatePerYear > _maxRate) {
            dbrRatePerYear = _maxRate;
            emit RateUpdate(_maxRate);
        }
    }

    function setDbrRatePerYear(uint _rate) external onlyGovOrOperator updateReserves {
        require(_rate <= maxDbrRatePerYear, "Rate exceeds max");
        dbrRatePerYear = _rate;
        emit RateUpdate(_rate);
    }

    function setDolaReserve(uint _dolaReserve) external onlyGov updateReserves {
        require(_dolaReserve > 0, "Dola reserve must be positive");
        uint K = dolaReserve * dbrReserve;
        dolaReserve = _dolaReserve;
        dbrReserve = K / _dolaReserve;
    }

    function setDbrReserve(uint _dbrReserve) external onlyGov updateReserves {
        require(_dbrReserve > 0, "DBR reserve must be positive");
        uint K = dolaReserve * dbrReserve;
        dbrReserve = _dbrReserve;
        dolaReserve = K / _dbrReserve;
    }

    function overrideReserves(uint _dbrReserve, uint _dolaReserve) external onlyGov {
        require(_dolaReserve > 0, "Dola reserve must be positive");
        require(_dbrReserve > 0, "DBR reserve must be positive");
        dolaReserve = _dolaReserve;
        dbrReserve = _dbrReserve;
        lastUpdate = block.timestamp;
    }

    function buyDBR(uint exactDolaIn, uint exactDbrOut, address to) external updateReserves {
        uint K = dolaReserve * dbrReserve;
        dolaReserve += exactDolaIn;
        dbrReserve -= exactDbrOut;
        require(dolaReserve * dbrReserve >= K, "Invariant");
        dola.transferFrom(msg.sender, address(this), exactDolaIn);
        dbr.mint(to, exactDbrOut);
        emit Buy(msg.sender, to, exactDolaIn, exactDbrOut);
    }

    function sendToSaleHandler() public {
        require(address(saleHandler) != address(0), "No sale handler");
        uint bal = dola.balanceOf(address(this));
        require(bal > 0, "No DOLA to send");
        uint capacity = saleHandler.getCapacity();
        uint amount = bal > capacity ? capacity : bal;
        dola.transfer(address(saleHandler), amount);
        saleHandler.onReceive();
    }

    function sweep(address token, address destination, uint amount) external onlyGov {
        IERC20(token).transfer(destination, amount);
    }

    event Buy(address indexed caller, address indexed to, uint dolaIn, uint dbrOut);
    event RateUpdate(uint newRate);
    event MaxRateUpdate(uint newMaxRate);
}
