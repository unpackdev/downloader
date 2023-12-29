// SPDX-License-Identifier: MIT

pragma solidity >=0.8.17;

import "./IENSRegistrarController.sol";

contract EndlessENSBulkRegister {
    struct Commitment {
        string name;
        address owner;
        bytes32 secret;
        address resolver;
        address addr;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "EndlessENSBulkRegister.onlyOwner: Access denied"
        );
        _;
    }

    // address public ensRegistrarController;
    IENSRegistrarController public ensRegistrarController;

    address owner;

    constructor(address _ensRegistrarController) {
        ensRegistrarController = IENSRegistrarController(
            _ensRegistrarController
        );
        owner = msg.sender;
    }

    event RegisterFailed(
        string name,
        address owner,
        bytes32 secret,
        uint256 duration,
        bytes errorInfo
    );

    event RegisterSuccess(
        string name,
        address owner,
        bytes32 secret,
        uint256 duration
    );

    event UpdateENSRegistrar(address oldENSRegistrar, address newENSRegistrar);

    function bulkRegister(
        string[] memory _names,
        address[] memory _owners,
        bytes32[] memory _secrets,
        uint256[] memory _durations
    ) external payable {
        uint256 totalLength = _names.length;
        require(
            totalLength == _owners.length,
            "EndlessENSBulkRegister.bulkRegister: Owner length does not match the domain names"
        );
        require(
            totalLength == _secrets.length,
            "EndlessENSBulkRegister.bulkRegister: Secret length does not match the domain names"
        );
        require(
            totalLength == _durations.length,
            "EndlessENSBulkRegister.bulkRegister: Duration length does not match the domain names"
        );
        require(
            msg.value >= getBulkRentPrice(_names, _durations),
            "EndlessENSBulkRegister.bulkRegister: Insufficient native token"
        );

        uint256 amtRem = msg.value;

        for (uint8 i = 0; i < _names.length; i++) {
            uint256 price = getRentPrice(_names[i], _durations[i]);
            bool errorOccured = false;

            try
                ensRegistrarController.register{value: price}(
                    _names[i],
                    _owners[i],
                    _durations[i],
                    _secrets[i]
                )
            {
                // continue
            } catch (bytes memory errorInfo) {
                errorOccured = true;
                emit RegisterFailed(
                    _names[i],
                    _owners[i],
                    _secrets[i],
                    _durations[i],
                    errorInfo
                );
            }
            if (errorOccured == false) {
                amtRem -= price;
                emit RegisterSuccess(
                    _names[i],
                    _owners[i],
                    _secrets[i],
                    _durations[i]
                );
            }
        }

        // Refund excess amount
        if (amtRem > 0) {
            (bool sent, ) = msg.sender.call{value: amtRem}("");
            require(sent, "Failed to send Ether");
        }
    }

    function bulkCommit(
        string[] memory _names,
        address[] memory _owners,
        bytes32[] memory _secrets,
        address[] memory _resolvers
    ) external {
        uint256 totalLength = _names.length;
        require(
            totalLength == _owners.length,
            "EndlessENSBulkRegister.bulkCommit: Owner length does not match the domain names"
        );
        require(
            totalLength == _secrets.length,
            "EndlessENSBulkRegister.bulkCommit: Secret length does not match the domain names"
        );

        if (_resolvers.length == 0) {
            for (uint8 i = 0; i < _names.length; i++) {
                bytes32 commitment = ensRegistrarController.makeCommitment(
                    _names[i],
                    _owners[i],
                    _secrets[i]
                );
                ensRegistrarController.commit(commitment);
            }
        } else {
            require(
                totalLength == _resolvers.length,
                "EndlessENSBulkRegister.bulkCommit: Resolvers length does not match the domain names"
            );
            for (uint8 i = 0; i < _names.length; i++) {
                bytes32 commitment = ensRegistrarController
                    .makeCommitmentWithConfig(
                        _names[i],
                        _owners[i],
                        _secrets[i],
                        _resolvers[i],
                        address(0) // Setting reverse resolution to 0x00000000000000000 for registration
                    );
                ensRegistrarController.commit(commitment);
            }
        }
    }

    function getBulkRentPrice(
        string[] memory _names,
        uint256[] memory _durations
    ) public view returns (uint256) {
        uint256 totalLength = _names.length;
        require(
            totalLength == _durations.length,
            "EndlessENSBulkRegister.getPriceRanges: Duration length does not match the domain names"
        );
        uint256 price;
        for (uint8 i = 0; i < _names.length; i++) {
            price += getRentPrice(_names[i], _durations[i]);
        }
        return price;
    }

    function setENSRegistrar(address _address) external onlyOwner {
        address oldENSRegistrarAddress = address(ensRegistrarController);
        ensRegistrarController = IENSRegistrarController(_address);
        emit UpdateENSRegistrar(
            oldENSRegistrarAddress,
            address(ensRegistrarController)
        );
    }

    function getRentPrice(
        string memory _name,
        uint256 _duration
    ) internal view returns (uint256) {
        return ensRegistrarController.rentPrice(_name, _duration);
    }
}
