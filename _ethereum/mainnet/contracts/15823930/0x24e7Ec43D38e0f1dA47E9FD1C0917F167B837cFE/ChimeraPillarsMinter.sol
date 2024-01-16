
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Local deps.
import "./Delegated.sol";
import "./Verify.sol";

// Main CP interface.
interface IChimeraPillars {
    function mintTo (uint16[] calldata quantity, address[] calldata recipient) external payable;
}

// Partner project interface.
interface IPartner {
    function balanceOf( address account ) external returns( uint );
}

// Partner schema.
struct Partner {
    string name;
    address contractAddress;
    uint256 price;
    string slug;
    uint16 minBalance;
    bool isActive;
    bool isMatic;
    bool isOS;
}

// Minter.
contract ChimeraPillarsMinter is Delegated, Verify {
    bool public isActive = false;

    Partner[] public partners;

    IChimeraPillars public ChimeraPillars = IChimeraPillars(0x6f3B255eFA6b2d4133c4F208E98E330e8CaF86f3);

    constructor (address _signer) {
        setSigner(_signer);
    }

    // Mint proxy.
    function mint (uint16 _quantity, uint256 _partnerId, bytes memory _signature) external payable {
        // Sanity check.
        require(isActive, "Mint is not active.");
        require(partners[_partnerId].contractAddress != address(0), "Invalid partner.");

        // Get partner.
        Partner storage partner = partners[_partnerId];

        // Ensure valid partner requirements.
        require(partner.isActive, "Partner mint is not active.");
        require(msg.value >= partner.price * _quantity, "Invalid ETH sent.");

        if (partner.isOS || partner.isMatic) {
            // Verify signature.
            require(verify(_quantity, _partnerId, _signature), "Invalid signature.");
        } else {
            // Verify balance.
            IPartner partnerContract = IPartner(partner.contractAddress);
            uint256 balance = partnerContract.balanceOf(msg.sender);
            require(balance >= partner.minBalance, "Not holding enough partner tokens for discount.");
        }

        // Convert to arrays.
        uint16[] memory quantity = new uint16[](1);
        quantity[0] = _quantity;
        address[] memory recipient = new address[](1);
        recipient[0] = msg.sender;

        // Proxy mint.
        ChimeraPillars.mintTo{ value: msg.value }(quantity, recipient);
    }

    function setIsActive (bool _isActive) external onlyDelegates {
        isActive = _isActive;
    }

    function setChimeraPillars (IChimeraPillars principal) external onlyDelegates {
        ChimeraPillars = principal;
    }

    function addPartner (
        string calldata _name,
        address _contractAddress,
        uint256 _price,
        string calldata _slug,
        uint16 _minBalance,
        bool _isActive,
        bool _isMatic,
        bool _isOS
    ) external onlyDelegates {
        Partner memory partner = Partner({
            name: _name,
            contractAddress: _contractAddress,
            price: _price,
            slug: _slug,
            minBalance: _minBalance,
            isActive: _isActive,
            isMatic: _isMatic,
            isOS: _isOS
        });

        partners.push(partner);
    }

    function editPartner (
        uint256 _id,
        string calldata _name,
        address _contractAddress,
        uint256 _price,
        string calldata _slug,
        uint16 _minBalance,
        bool _isActive,
        bool _isMatic,
        bool _isOS
    ) external onlyDelegates {
        require(partners[_id].contractAddress != address(0), "Invalid partner." );

        Partner storage partner = partners[_id];

        partner.name = _name;
        partner.contractAddress = _contractAddress;
        partner.price = _price;
        partner.slug = _slug;
        partner.minBalance = _minBalance;
        partner.isActive = _isActive;
        partner.isMatic = _isMatic;
        partner.isOS = _isOS;
    }
}