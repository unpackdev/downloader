// SPDX-License-Identifier: MIT

import "./Ownable.sol";
import "./ERC2981.sol";
import "./ERC721A.sol";

pragma solidity 0.8.13;

/*
 * Inherit the same spirit of RR/BAYC and move on to the beta phase.
 */
contract RRBAYCBeta is Ownable, ERC721A, ERC2981 {
    error ErrorPreparedAlready();
    error ErrorNotRolling();
    error ErrorRollingAlready();
    error ErrorBadAmount(uint256 amout, uint256 max);
    error ErrorTooEager();
    error ErrorJustifiedAlready();
    error ErrorPaymentDeficit(uint256 actual, uint256 expected);

    address public constant RR = 0x592814FF14E030B51F6087032DB0f88F4214F254;
    uint256 public constant ticketToTruth = 3e15;
    uint256 public constant maxApesInBeta = 3101;
    uint256 public constant earlyApes = 600;
    uint256 public constant dontBeGreedy = 10;

    mapping(address => bool) public justified;
    bool public rolling = false;
    string public root;

    constructor() ERC721A("RR/BAYC Beta", "RBB") {
        _setDefaultRoyalty(msg.sender, 500);
    }

    function mint(uint256 amount) external payable {
        if (!rolling) {
            revert ErrorNotRolling();
        }
        if (amount == 0) {
            revert ErrorBadAmount(amount, dontBeGreedy);
        }
        if (_totalMinted() + amount > maxApesInBeta) {
            revert ErrorTooEager();
        }

        bool outOfThinAir = msg.value == 0;
        if (outOfThinAir) {
            if (amount > 1) {
                revert ErrorBadAmount(amount, 1);
            }
            if (justified[msg.sender]) {
                revert ErrorJustifiedAlready();
            }
            if (_totalMinted() >= earlyApes) {
                revert ErrorPaymentDeficit(0, ticketToTruth);
            }
            justified[msg.sender] = true;
        } else {
            if (amount > dontBeGreedy) {
                revert ErrorBadAmount(amount, dontBeGreedy);
            }
            uint256 expected = amount * ticketToTruth;
            if (msg.value < expected) {
                revert ErrorPaymentDeficit(msg.value, expected);
            }
        }

        _safeMint(msg.sender, amount);
    }

    /// @notice credit to the whistleblower
    function prepare() external onlyOwner {
        if (_totalMinted() != 0) {
            revert ErrorPreparedAlready();
        }
        _safeMint(RR, 1);
    }

    function cutLoose() external onlyOwner {
        if (rolling) {
            revert ErrorRollingAlready();
        }
        rolling = true;
    }

    function plantRoot(string memory newRoot) external onlyOwner {
        root = newRoot;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(msg.sender).transfer(balance);
        }
    }

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override returns (string memory) {
        return root;
    }
}
