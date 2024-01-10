// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// Client errors
error InvalidArgument();
error Unauthorized();    // 401
error PaymentRequired(); // 402
error Forbidden();       // 403
error NotFound();        // 404
error Conflict();        // 409
error TooManyRequests(); // 429

// Contract errors
error OutOfBounds();
error InternalError();      // 500
error ServiceUnavailable(); // 503
