// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./StringsUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./AddressUpgradeable.sol";

contract XCO2 is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, PausableUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {

    // [tier 1 bulk, tier 2 bulk, mint and burn discount]
    uint[3] public discountPercents;
    uint[2] public bulkDiscountAmounts;
    
    uint public totalMinted;
    uint public totalRetired;
    uint public txNum;
    uint public maxSupply;
    uint public retireOnMintAmount;
    uint public xco2Needed;
    uint toEth;
    address paymentAddr;

    uint private pricePerToken;

    mapping (address => uint256) public retiredBalanceOf;
    
    event Retired(uint indexed txNum, address indexed addr, uint amount, string fn);

    function initialize() external initializer{
        __ERC20_init("XCO2 Coin", "XCO2");
        __Ownable_init();
        __ERC20Burnable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        toEth = 10 ** 18;
        discountPercents = [10, 20, 10]; //[tier 1 bulk 1, tier 2 bulk, mint/retire ]
        bulkDiscountAmounts = [100, 10000];
        totalMinted = 0;
        totalRetired = 0;
        txNum = 0;
        maxSupply = 10 ** 25;
        retireOnMintAmount = 84458571429000;
        xco2Needed = 1295978200;
        pricePerToken = 2200000000000000;
        paymentAddr = owner();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint amount) 
        public 
        whenNotPaused
        nonReentrant
        payable 
    {
        if (msg.sender != owner()) {
            require(msg.value >0);
            require(msg.value == getTotalPrice(amount, false));
            withdraw(msg.value);
        }
        uint mintAmount = amount * toEth;
        require(totalMinted + retireOnMintAmount + mintAmount <= maxSupply);
        totalMinted += mintAmount + retireOnMintAmount;
        totalRetired += retireOnMintAmount;
        retiredBalanceOf[address(this)] += retireOnMintAmount;
        _mint(to, mintAmount);
        txNum++;
        emit Retired(txNum, to, retireOnMintAmount, "mint");
    }

    function mintAndBurn(address to, uint amount) 
        public 
        whenNotPaused
        nonReentrant
        payable 
    {
        if (msg.sender != owner()) {
            require(msg.value >0);
            require(msg.value == getTotalPrice(amount, true));
            withdraw(msg.value);
        }
        uint mintAmount = amount * toEth;
        require(totalMinted + mintAmount <= maxSupply);
        totalMinted += mintAmount;
        totalRetired += mintAmount;
        retiredBalanceOf[to] += mintAmount;
        txNum++;
        emit Retired(txNum, to, mintAmount, "mint_burn");
    }

    function burn(uint256 amount) 
        public
        whenNotPaused  
        virtual 
        override 
    {
        _burn(msg.sender, amount);
        totalRetired += amount;
        retiredBalanceOf[msg.sender] += amount;
        txNum++;
        emit Retired(txNum, msg.sender, amount, "burn");
    }

    function _beforeTokenTransfer(address from, address to, uint amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function getTotalPrice(uint amount, bool immediateRetire) public view returns (uint) {
        uint discountPrice = pricePerToken;
        if (immediateRetire) {
            discountPrice -= discountPrice * discountPercents[2] / 100;
        }
        if (amount >= bulkDiscountAmounts[1]) {
            discountPrice -= discountPrice * discountPercents[1] / 100;
        }
        else if (amount >= bulkDiscountAmounts[0]) {
            discountPrice -= discountPrice * discountPercents[0] / 100;
        }
        return discountPrice * amount;
    }

    function setPrice(uint price) public onlyOwner {
        pricePerToken = price;
    }
     function setDiscountPercents(uint[] memory percents) public onlyOwner {
        discountPercents[0] = percents[0];
        discountPercents[1] = percents[1];
        discountPercents[2] = percents[2];
    }
     function setBulkDiscountAmounts(uint[] memory bulkAmounts) public onlyOwner {
        bulkDiscountAmounts[0] = bulkAmounts[0];
        bulkDiscountAmounts[1] = bulkAmounts[1];
    }
    function setMaxSupply(uint newMax) public onlyOwner {
        maxSupply = newMax;
    }
    function setRetireOnMintAmount(uint newAmount) public onlyOwner {
        retireOnMintAmount = newAmount;
    }
    function setNewXco2Needed(uint newXco2Needed) public onlyOwner {
        xco2Needed = newXco2Needed;
    }
    function setPayentAddre(address addr) public onlyOwner {
        paymentAddr = addr;
    }

    function withdraw(uint amount) internal {
        AddressUpgradeable.sendValue(payable(paymentAddr), amount);
    }

    function genCert(address addr) public view returns (string memory) {
        return string(
            abi.encodePacked(
                '<svg class="svgBody" width="250" height="150" viewBox="0 0 250 150" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                '<rect class="o" width="250" height="150"/>',
                '<rect class="n" x="2.48" y="2.26" width="245" height="145"/>',
                '<text class="h"><tspan x="18" y="30" class="med">X</tspan></text>',
                '<text class="i"><tspan class="med" x="32" y="30">CO2 Carbon Offset</tspan></text>',
                '<text x="15" y="57" class="b small">', getTonsOffset(retiredBalanceOf[addr]), '</text>',
                '<text x="15" y="75" class="b tiny">', addressToString(addr) ,'</text>',
                '<path class="o" d="M53.96,90.23l-7.43-2.53c-.09-.03-.21-.05-.33-.05s-.24,.02-.33,.05l-7.44,2.53c-.18,.06-.33,.27-.33,.46v10.55c0,.19,.13,.45,.28,.57l7.54,5.88c.07,.06,.18,.09,.28,.09s.2-.03,.28-.09l7.54-5.88c.15-.12,.28-.37,.28-.57v-10.55c0-.19-.14-.4-.33-.46Zm-3.77,3.74l-4.65,6.4c-.11,.16-.33,.19-.49,.07-.03-.02-.06-.05-.07-.07l-2.76-3.81c-.08-.11,0-.28,.14-.28h1.21c.11,0,.22,.06,.28,.15l1.42,1.95,3.3-4.55c.07-.09,.17-.15,.28-.15h1.21c.14,0,.22,.17,.14,.28Z"/>',
                '<text class="j sm gr"><tspan x="60" y="102">Blockchain Certified</tspan></text>',
                '<text class="j jf" transform="translate(14.68 120.15)">',
                '<tspan x="0" y="0">This image is rendered directly from the blockchain</tspan>',
                '<tspan x="0" y="10.34">to serve as cryptographic proof of carbon offset for</tspan>',
                '<tspan x="0" y="20.67">the listed wallet address from retired XCO2 tokens.</tspan>',
                '<style>.svgBody {font-family: "Courier New" } .tiny {font-size:8.8px; } .small {font-size: 14px;} .med{font-size:22px;} .sm {font-size:15px;} .gr{fill:#157e23}.h,.i,.j{font-family:Montserrat-Regular, Montserrat, "Courier New";}.i,.jf{fill:#6d6e71;}.n{fill:#fff;}.o,.h{fill:#39b54a;}.h{font-size:21.36px;}.jf{font-size:8.61px;}</style>',
                '</svg>'
            ));
    }

    function addressToString(address addr) internal pure returns (string memory){
        // Cast Address to byte array
        bytes memory addressBytes = abi.encodePacked(addr);

        // Byte array for the new string
        bytes memory stringBytes = new bytes(42);

        // Assign firs two bytes to '0x'
        stringBytes[0] = '0';
        stringBytes[1] = 'x';

        // Iterate over every byte in the array
        // Each byte contains two hex digits that gets individually converted
        // into their ASCII representation and add to the string
        for (uint256 i = 0; i < 20; i++) {
            // Convert hex to decimal values
            uint8 leftValue = uint8(addressBytes[i]) / 16;
            uint8 rightValue = uint8(addressBytes[i]) - 16 * leftValue;

            // Convert decimals to ASCII Values
            bytes1 leftChar = leftValue < 10 ? bytes1(leftValue + 48) : bytes1(leftValue + 87);
            bytes1 rightChar = rightValue < 10 ? bytes1(rightValue + 48) : bytes1(rightValue + 87);

            // Add ASCII values to the string byte array
            stringBytes[2 * i + 3] = rightChar;
            stringBytes[2 * i + 2] = leftChar;
        }

        // Cast byte array to string and return
        return string(stringBytes);
    }
    function xco2AmountInWeiToOffsetGas(uint256 gasCostInGWei) public view returns(uint256){
        // 1295978200g / ETH
        // 1 Token = 100 kg
        return ((gasCostInGWei * xco2Needed) / 10**9) * 100;
    }
    
    function getTonsOffset(uint retiredBalance) internal pure returns (string memory){

        // 10 Tokens = 1 Ton
        // 1 Ton = 907.18474 kilograms
        // 1 Token = 90.718474 kilograms

        uint256 carbonOffsetInt = 0;
        string memory units = " Tons Offset";
        bool validValue = false;
        string memory cOffset;

        if (retiredBalance >= 10**18){

            carbonOffsetInt = retiredBalance / 10**18;

            cOffset = StringsUpgradeable.toString(retiredBalance / 10**9);

            bytes memory stringLen = bytes(cOffset);

            cOffset = substring(cOffset, (stringLen.length - 9), (stringLen.length - 1));

            validValue = true;

        } else if (retiredBalance >= 10**12){

            if (retiredBalance >= 10**15){
                // KG amount
                retiredBalance *= 907184740;
                units = " Kilos Offset";
            } else{
                // g amount
                retiredBalance *= 907184740000;
                units = " grams Offset";
            }
            
            carbonOffsetInt = retiredBalance / 10**24;

            cOffset = StringsUpgradeable.toString(retiredBalance / 10**15);

            bytes memory stringLen = bytes(cOffset);

            cOffset = substring(cOffset, (stringLen.length - 9), (stringLen.length - 1));

            validValue = true;
        }

        if (validValue){
            return string(abi.encodePacked(StringsUpgradeable.toString(carbonOffsetInt), ".", cOffset, units));
        }
         else {
            return "Not enough to calculate";
        }
    }

    function substring(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory ) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }
}