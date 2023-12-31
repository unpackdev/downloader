/** 
Decentralized Bank Digital Currency 

Creating The Future With DBDC.
At Decentralized Bank Digital Currency (DBDC), we are catalysts for change, 
igniting a revolution that challenges the status quo of the financial world. 
Our mission is to empower individuals and communities to take control of their financial destinies, 
and together, we are redefining the future of finance through decentralization. 
Imagine a financial system that is transparent, inclusive, and accountable. 
A system where power is distributed among the people, and opportunities are not limited to a select few. 
This is the world we envision, where financial sovereignty is within reach for everyone.

Current Pain Points
The centralized financial system has proven to be inherently flawed and prone to failures, as evidenced by real-world examples:

-Lack of Transparency
Traditional listing mechanisms often operate behind closed doors, 
leaving investors unaware of the true state of listed institutions. 
This lack of transparency contributed to the financial crisis of 2008, 
where complex financial products were marketed without full disclosure of underlying risks.

-Regulatory Oversights
Despite claims of effective regulatory protocols, major financial institutions like Lehman Brothers collapsed in 2008, 
leading to a global financial crisis. 
The regulatory oversight failed to identify and address the excessive risks taken by these institutions, 
resulting in severe consequences for the broader economy.

-Systemic Risks
The concentration of power in centralized entities poses significant systemic risks. 
For instance, when investment bank Bear Stearns faced a liquidity crisis in 2008, 
the interconnectedness of the financial system led to a domino effect, exacerbating the global financial crisis.

-Scandals and Fraud
The Enron scandal serves as a prominent example of corporate malfeasance. 
Enron, once a leading energy company, manipulated financial statements, 
leading to its bankruptcy and significant losses for investors. Similarly, 
the collapse of MF Global in 2011 exposed fraudulent practices, resulting in substantial investor losses.

-Lack of Accountability
Failures within the centralized financial system often reveal a lack of accountability. 
Regulators and institutions frequently evade responsibility for their actions, 
leading to public distrust and frustration.

**/
// whitepaper https://dbdc.capital/wp-content/uploads/2023/07/Whitepaper.pdf
// website    https://dbdc.capital/
// telegram   https://t.me/DecentralizedBankDigitalCurrency
// twitter    https://twitter.com/DDBC_ERC20
// PinkSale  https://www.pinksale.finance/launchpad/0x652809fB925DB172EFe0CB00B4e56baCBfF177F5?chain=ETH

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract DBDC is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Decentralized Bank Digital Currency", "DBDC") {
        _mint(msg.sender,  1000000000 * (10 ** decimals())); 
    }

}
