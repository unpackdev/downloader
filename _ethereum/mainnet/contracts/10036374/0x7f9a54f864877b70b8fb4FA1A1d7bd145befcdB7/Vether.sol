pragma solidity 0.6.4;
//ERC20 Interface
interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    }
// Uniswap Factory Interface
interface UniswapFactory {
    function getExchange(address token) external view returns (address exchange);
    }
// Uniswap Exchange Interface
interface UniswapExchange {
    function tokenToEthTransferInput(uint256 tokens_sold,uint256 min_eth,uint256 deadline, address recipient) external returns (uint256  eth_bought);
    }
    //======================================VETHER=========================================//
contract Vether is ERC20 {
    // ERC-20 Parameters
    string public name; string public symbol;
    uint256 public decimals; uint256 public override totalSupply;
    // ERC-20 Mappings
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;
    // Public Parameters
    uint256 public emission;
    uint256 public currentEra; uint256 public currentDay;
    uint256 public daysPerEra; uint256 public secondsPerDay;
    uint256 public genesis; uint256 public nextEraTime; uint256 public nextDayTime;
    address payable public burnAddress;
    address[2] public registryAddrArray; bool public lockMutable;
    uint256 public totalFees; uint256 public totalBurnt;
    // Public Mappings
    mapping(uint256=>uint256) public mapEra_Emission;                                           // Era->Emission
    mapping(uint256=>mapping(uint256=>uint256)) public mapEraDay_Units;                         // Era,Days->Units
    mapping(uint256=>mapping(uint256=>uint256)) public mapEraDay_UnitsRemaining;                // Era,Days->TotalUnits
    mapping(uint256=>mapping(uint256=>uint256)) public mapEraDay_Emission;                      // Era,Days->Emission
    mapping(uint256=>mapping(uint256=>uint256)) public mapEraDay_EmissionRemaining;             // Era,Days->Emission
    mapping(uint256=>mapping(uint256=>mapping(address=>uint256))) public mapEraDay_MemberUnits; // Era,Days,Member->Units
    mapping(address=>mapping(uint256=>uint[])) public mapMemberEra_Days;                        // Member,Era->Days[]
    mapping(address=>bool) public mapAddress_Excluded;                                          // Address->Excluded
    // Events
    event NewEra(uint256 era, uint256 emission, uint256 time);
    event NewDay(uint256 era, uint256 day, uint256 time);
    event Burn(address indexed payer, address indexed member, uint256 era, uint256 day, uint256 units);
    event Withdrawal(address indexed caller, address indexed member, uint256 era, uint256 day, uint256 value);

    //=====================================CREATION=========================================//
    // Constructor
    constructor() public {
        name = "value-test"; symbol = "val"; decimals = 18; totalSupply = 1000000*10**decimals;
        emission = 2048*10**decimals; currentEra = 1; currentDay = 1;                       // Set emission, Era and Day
        genesis = now; daysPerEra = 4; secondsPerDay = 60;                                  // Set genesis time
        burnAddress = 0x000000000000000000000000000000000000dEaD;                           // Set Burn Address
        registryAddrArray[0] = 0xf5D915570BC477f9B8D6C0E980aA81757A3AaC36;                  // Set UniSwap V1 Mainnet
        registryAddrArray[0] = 0xfB02641a0752B4d53DAbB8B2d75C92C1858a7a4E;                  // Set UniSwap V1 Mainnet
        
        balanceOf[address(this)] = totalSupply; 
        emit Transfer(address(0), address(this), totalSupply);                              // Mint the total supply to this address
        nextEraTime = genesis + (secondsPerDay * daysPerEra);                               // Set next time for coin era
        nextDayTime = genesis + secondsPerDay;                                              // Set next time for coin day
        mapAddress_Excluded[address(this)] = true; lockMutable = true;                      // Add this address to be excluded from fees
        mapEra_Emission[currentEra] = emission;                                             // Map Starting emission
        mapEraDay_EmissionRemaining[currentEra][currentDay] = emission; 
        mapEraDay_Emission[currentEra][currentDay] = emission;
    }
    //========================================ERC20=========================================//
    // ERC20 Transfer function
    function transfer(address to, uint256 value) public override returns (bool success) {
        _transfer(msg.sender, to, value);
        return true;
    }
    // ERC20 Approve function
    function approve(address spender, uint256 value) public override returns (bool success) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    // ERC20 TransferFrom function
    function transferFrom(address from, address to, uint256 value) public override returns (bool success) {
        require(value <= allowance[from][msg.sender], 'Must not send more than allowance');
        allowance[from][msg.sender] -= value;
        _transfer(from, to, value);
        return true;
    }
    // Internal transfer function which includes the Fee
    function _transfer(address _from, address _to, uint256 _value) private {
        require(balanceOf[_from] >= _value, 'Must not send more than balance');
        require(balanceOf[_to] + _value >= balanceOf[_to], 'Balance overflow');
        balanceOf[_from] -= _value;
        uint256 _fee = _getFee(_from, _value);                                              // Get fee amount
        balanceOf[_to] += (_value - _fee);                                                  // Add to receiver
        balanceOf[address(this)] += _fee;                                                   // Add fee to self
        totalFees += _fee;                                                                  // Track fees collected
        emit Transfer(_from, _to, (_value - _fee));                                         // Transfer event
        if (!mapAddress_Excluded[_from]) {
            emit Transfer(_from, address(this), _fee);                                      // Fee Transfer event
        }
    }
    // Calculate Fee amount
    function _getFee(address _from, uint256 _value) private view returns (uint256) {
        if (mapAddress_Excluded[_from]) {
           return 0;                                                                        // No fee if excluded
        } else {
            return (_value / 1000);                                                         // Fee amount = 0.1%
        }
    }
    //==================================PROOF-OF-VALUE======================================//
    // Calls when sending Ether
    receive() external payable {
        burnAddress.call.value(msg.value)("");                                              // Burn ether
        _recordBurn(msg.sender, msg.sender, currentEra, currentDay, msg.value);             // Record Burn
    }
    // Burn ether for nominated member
    function burnEtherForMember(address member) external payable {
        burnAddress.call.value(msg.value)("");                                              // Burn ether
        _recordBurn(msg.sender, member, currentEra, currentDay, msg.value);                 // Record Burn
    }
    // Burn ERC-20 Tokens
    function burnTokens(address token, uint256 amount) external {
        _burnTokens(token, amount, msg.sender);                                             // Record Burn
    }
    // Burn tokens for nominated member
    function burnTokensForMember(address token, uint256 amount, address member) external {
        _burnTokens(token, amount, member);                                                 // Record Burn
    }
    // Calls when sending Tokens
    function _burnTokens (address _token, uint256 _amount, address _member) private {
        uint256 _eth; address _ex = getExchange(_token);                                    // Get exchange
        if (_ex == address(0)) {                                                            // Handle Token without Exchange
            uint256 _startGas = gasleft();                                                  // Start counting gas
            ERC20(_token).transferFrom(msg.sender, address(this), _amount);                 // Must collect tokens
            ERC20(_token).transfer(burnAddress, _amount);                                   // Burn token
            uint256 gasPrice = tx.gasprice; uint256 _endGas = gasleft();                    // Stop counting gas
            uint256 _gasUsed = (_startGas - _endGas) + 20000;                               // Calculate gas and add gas overhead
            _eth = _gasUsed * gasPrice;                                                     // Attribute gas burnt
        } else {
            ERC20(_token).transferFrom(msg.sender, address(this), _amount);                 // Must collect tokens
            ERC20(_token).approve(_ex, _amount);                                            // Approve Exchange contract to transfer
            _eth = UniswapExchange(_ex).tokenToEthTransferInput(
                    _amount, 1, block.timestamp + 10, burnAddress);                         // Uniswap Exchange Transfer function
        }
        _recordBurn(msg.sender, _member, currentEra, currentDay, _eth);
    }
    // Get Token Exchange
    function getExchange(address token ) public view returns (address){
        address exchangeToReturn = address(0);
        address exchangeFound = UniswapFactory(registryAddrArray[0]).getExchange(token);    // Try UniSwap V1
        if (exchangeFound != address(0)) {
            exchangeToReturn = exchangeFound;
        } else {
            exchangeToReturn = UniswapFactory(registryAddrArray[1]).getExchange(token);     // Try DefSwap
        }
        return exchangeToReturn;
    }
    // Internal - Records burn
    function _recordBurn(address _payer, address _member, uint256 _era, uint256 _day, uint256 _eth) private {
        if (mapEraDay_MemberUnits[_era][_day][_member] == 0){                               // If hasn't contributed to this Day yet
            mapMemberEra_Days[_member][_era].push(_day);                                    // Add it
        }
        mapEraDay_MemberUnits[_era][_day][_member] += _eth;                                 // Add member's share
        mapEraDay_UnitsRemaining[_era][_day] += _eth;                                       // Add to total historicals
        mapEraDay_Units[_era][_day] += _eth;                                                // Add to total outstanding
        totalBurnt += _eth;                                                                 // Add to total burnt
        emit Burn(_payer, _member, _era, _day, _eth);                                       // Burn event
        _updateEmission();                                                                  // Update emission Schedule
    }
    // Allows adding an excluded address, once per Era
    function addExcluded(address excluded) external {                   
        if(!lockMutable){                                                                   // Rate limiting
            _transfer(msg.sender, address(this), mapEra_Emission[1]/2);                     // Pay fee of 1024 Vether
            lockMutable = true;                                                             // Lock contract for another Era
            mapAddress_Excluded[excluded] = true;                                           // Add desired address
        }
    }
    //======================================WITHDRAWAL======================================//
    // Used to efficiently track participation in each era
    function getDaysContributedForEra(address member, uint256 era) public view returns(uint256){
        return mapMemberEra_Days[member][era].length;
    }
    // Call to withdraw a claim
    function withdrawShare(uint256 era, uint256 day) external {
        _withdrawShare(era, day, msg.sender);                           
    }
    // Call to withdraw a claim for another member
    function withdrawShareForMember(uint256 era, uint256 day, address member) external {
        _withdrawShare(era, day, member);
    }
    // Internal - withdraw function
    function _withdrawShare (uint256 _era, uint256 _day, address _member) private {
        _updateEmission();                                                                  // Update emission Schedule
        if (_era < currentEra) {                                                            // Allow if in previous era
            _processWithdrawal(_era, _day, _member);                                        // Process Withdrawal
        } else if (_era == currentEra) {                                                    // Handle if in current era
            if (_day < currentDay) {                                                        // Allow only if in previous day
                _processWithdrawal(_era, _day, _member);                                    // Process Withdrawal
            }
        }   
    }
    // Internal - Withdrawal function
    function _processWithdrawal (uint256 _era, uint256 _day, address _member) private {
        uint256 memberUnits = mapEraDay_MemberUnits[_era][_day][_member];                   // Get Member Units
        if (memberUnits == 0) {                                                             // Do nothing if 0 (prevents revert)
        } else {
            uint256 emissionToTransfer = getEmissionShare(_era, _day, _member);             // Get the emission Share for Member
            mapEraDay_MemberUnits[_era][_day][_member] = 0;                                 // Set to 0 since it will be withdrawn
            mapEraDay_UnitsRemaining[_era][_day] -= memberUnits;                            // Decrement Member Units
            mapEraDay_EmissionRemaining[_era][_day] -= emissionToTransfer;                  // Decrement emission
            _transfer(address(this), _member, emissionToTransfer);                          // ERC20 transfer function
            emit Withdrawal(msg.sender, _member, _era, _day, emissionToTransfer);           // Withdrawal Event
        }
    }
         // Get emission Share function
    function getEmissionShare(uint256 era, uint256 day, address member) public view returns (uint256 emissionShare) {
        uint256 memberUnits = mapEraDay_MemberUnits[era][day][member];                      // Get Member Units
        if (memberUnits == 0) {
            return 0;                                                                       // If 0, return 0
        } else {
            uint256 totalUnits = mapEraDay_UnitsRemaining[era][day];                        // Get Total Units
            uint256 emissionRemaining = mapEraDay_EmissionRemaining[era][day];              // Get emission remaining for Day
            uint256 balance = balanceOf[address(this)];                                     // Find remaining balance
            if (emissionRemaining > balance) { emissionRemaining = balance; }               // In case less than required emission
            emissionShare = (emissionRemaining * memberUnits) / totalUnits;                 // Calculate share
            return  emissionShare;                            
        }
    }
    //======================================EMISSION========================================//
    // Internal - Update emission function
    function _updateEmission() private {
        uint256 _now = now;                                                                 // Find now()
        if (_now >= nextDayTime) {                                                          // If time passed the next Day time
            if (currentDay >= daysPerEra) {                                                 // If time passed the next Era time
                currentEra += 1; currentDay = 0;                                            // Increment Era, reset Day
                nextEraTime = _now + (secondsPerDay * daysPerEra);                          // Set next Era time
                lockMutable = false;
                emission = getNextEraEmission();                                            // Get correct emission
                mapEra_Emission[currentEra] = emission;                                     // Map emission to Era
                emit NewEra(currentEra, emission, nextEraTime);                             // Emit Event
            }
            currentDay += 1;                                                                // Increment Day
            nextDayTime = _now + secondsPerDay;                                             // Set next Day time
            emission = getDayEmission();                                                    // Check daily Dmission
            mapEraDay_Emission[currentEra][currentDay] = emission;                          // Map emission to Day
            mapEraDay_EmissionRemaining[currentEra][currentDay] = emission;                 // Map emission to Day
            emit NewDay(currentEra, currentDay, nextDayTime);                               // Emit Event
        }
    }
    // Calculate Era emission
    function getNextEraEmission() public view returns (uint256) {
        uint256 _1 = 1*10**18;
        if (emission > _1) {                                                                // Normal emission Schedule
            return emission / 2;                                                            // emissions: 2048 -> 1.0
        } else{                                                                             // Enters Fee Era
            return _1;                                                                      // Return 1.0 from fees
        }
    }
    // Calculate Day emission
    function getDayEmission() public view returns (uint256) {
        uint256 balance = balanceOf[address(this)];                                         // Find remaining balance
        if (balance > emission) {                                                           // Balance is sufficient
            return emission;                                                                // Return emission
        } else {                                                                            // Balance has dropped low
            return balance;                                                                 // Return full balance
        }
    }
}