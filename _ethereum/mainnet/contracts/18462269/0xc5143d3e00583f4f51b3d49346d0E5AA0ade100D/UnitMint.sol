// SPDX-License-Identifier: MIT

pragma solidity >=0.8.17;
import "./Unit.sol";

contract UnitMint {
    mapping(address => bool) public isAdmin;

    uint256 public price = 0.1 ether;

    uint256 public iterator;
    address public unitAddress;
    address signer;
    address recipient;
    bool public mintOpened;

    constructor(address _unitAddress, address _recipient) {
        recipient = _recipient;
        unitAddress = _unitAddress;
        iterator = 1;
        signer = msg.sender;
        isAdmin[msg.sender] = true;
    }

    modifier adminOnly() {
        require(isAdmin[msg.sender], "Unauthorized");
        _;
    }

    modifier allowed(
        uint256[] calldata _templateIds,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) {
        require(
            signer ==
                ecrecover(
                    keccak256(
                        abi.encodePacked(
                            "\x19Ethereum Signed Message:\n32",
                            keccak256(
                                abi.encodePacked(
                                    address(this),
                                    _templateIds,
                                    iterator
                                )
                            )
                        )
                    ),
                    v,
                    r,
                    s
                ),
            "Invalid mint data"
        );
        _;
    }

    function setSigner(address _signer) external adminOnly {
        signer = _signer;
    }

    function setRecipients(address _recipient) external adminOnly {
        recipient = _recipient;
    }

    function mint(
        address _to,
        uint256[] calldata _templateIds,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable allowed(_templateIds, v, r, s) {
        require(msg.value >= price, "Insufficient funds");
        require(mintOpened, "Mint Closed");
        bool successTransfer = payable(recipient).send(price);
        require(successTransfer, "Could not transfer funds to recipient");
        for (uint8 i = 0; i < _templateIds.length; i++) {
            Void2122Unit(unitAddress).mint(_to, _templateIds[i]);
        }
        iterator++;
    }

    function setPrice(uint256 _price) external adminOnly {
        price = _price;
    }

    function toggleMintState() external adminOnly {
        mintOpened = !mintOpened;
    }

    function withdraw(address _recipient) external adminOnly {
        payable(_recipient).transfer(address(this).balance);
    }
}
