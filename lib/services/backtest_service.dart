import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/backtest_models.dart';
import 'package:logging/logging.dart';
import 'dart:async';

/// Backtest API service class for handling strategy management and backtest operations
class BacktestService {
  // Logger configuration
  static final _logger = Logger('BacktestService');
  static bool _isInitialized = false;

  // Base URL for the API
  static const String baseUrl =
      'https://replacing-piece-wc-fit.trycloudflare.com/api';

  /// Static class initialization for logging
  static void initialize() {
    if (_isInitialized) return;

    // Set up logging
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      if (record.loggerName == 'BacktestService') {
        // ignore: avoid_print
        print(
            '[${record.level.name}] (${record.loggerName}) ${record.message}');
        if (record.error != null) {
          print('  ERROR: ${record.error}');
        }
        if (record.stackTrace != null) {
          print('  STACKTRACE: ${record.stackTrace}');
        }
      }
    });

    _logger.info("BacktestService initialized. API URL: $baseUrl");
    _isInitialized = true;
  }

  /// Get all available strategies
  static Future<List<BacktestStrategy>> getStrategies() async {
    final url = Uri.parse('$baseUrl/backtesting/strategies');
    _logger.info('GET request: $url');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      _logger.info('Response received: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Decode with UTF-8 to handle Turkish characters
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonResponse = json.decode(decodedBody);

        if (jsonResponse is Map &&
            jsonResponse.containsKey('status') &&
            jsonResponse['status'] == 'success') {
          if (jsonResponse.containsKey('strategies') &&
              jsonResponse['strategies'] is List) {
            final List<dynamic> strategiesJson =
                jsonResponse['strategies'] as List;

            // Check if the list is empty
            if (strategiesJson.isEmpty) {
              _logger.info('No strategies found on the server.');
              return [];
            }

            final strategies = strategiesJson
                .map((json) {
                  try {
                    return BacktestStrategy.fromJson(
                        json as Map<String, dynamic>);
                  } catch (e, stackTrace) {
                    _logger.severe(
                        'Error parsing strategy JSON: $json', e, stackTrace);
                    return null;
                  }
                })
                .whereType<BacktestStrategy>() // Filter out null results
                .toList();

            _logger.info(
                '${strategies.length} strategies successfully retrieved and parsed.');
            return strategies;
          } else {
            _logger.warning(
                "API response successful ('status':'success') but 'strategies' list missing or wrong format.");
            throw Exception(
                "API response format not as expected (strategies list missing).");
          }
        } else {
          // Failed status or missing status field
          final errorMsg =
              (jsonResponse is Map && jsonResponse.containsKey('message'))
                  ? jsonResponse['message']
                  : 'API returned unsuccessful or unexpected response';
          _logger.warning('API error (status != success): $errorMsg');
          throw Exception(errorMsg);
        }
      } else {
        // HTTP status code other than 200
        _logger.warning(
            'API returned code ${response.statusCode}. Response: ${response.body}');
        throw Exception('API returned code ${response.statusCode}.');
      }
    } on http.ClientException catch (e, stackTrace) {
      _logger.severe(
          'Network error (ClientException): Could not get strategies.',
          e,
          stackTrace);
      throw Exception('Network error: Server may be unreachable. ($e)');
    } on TimeoutException catch (e, stackTrace) {
      _logger.severe(
          'Request timed out: Could not get strategies.', e, stackTrace);
      throw Exception('Server did not respond (timeout).');
    } catch (e, stackTrace) {
      // All other errors (JSON parse error, etc.)
      _logger.severe('General error getting strategies.', e, stackTrace);

      // Provide a more user-friendly message based on error type
      if (e is FormatException) {
        throw Exception('API response could not be read (invalid format).');
      }

      // More user-friendly message instead of rethrowing the original error
      throw Exception('An error occurred while retrieving strategies.');
    }
  }

  /// Get a strategy by ID
  static Future<BacktestStrategy> getStrategy(String id) async {
    final url = Uri.parse('$baseUrl/backtesting/strategies/$id');
    _logger.info('GET request (single strategy): $url');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      _logger.info('Response received: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonResponse = json.decode(decodedBody);

        if (jsonResponse is Map &&
            jsonResponse.containsKey('status') &&
            jsonResponse['status'] == 'success') {
          if (jsonResponse.containsKey('strategy') &&
              jsonResponse['strategy'] is Map) {
            final strategy = BacktestStrategy.fromJson(
                jsonResponse['strategy'] as Map<String, dynamic>);
            _logger.info(
                'Strategy successfully retrieved: ${strategy.name} (ID: $id)');
            return strategy;
          } else {
            _logger.warning(
                "API response successful but 'strategy' object missing/wrong format.");
            throw Exception(
                "API response format not as expected (strategy object missing).");
          }
        } else {
          final errorMsg =
              (jsonResponse is Map && jsonResponse.containsKey('message'))
                  ? jsonResponse['message']
                  : 'API returned unsuccessful response';
          _logger.warning('API error (status != success): $errorMsg');
          throw Exception(errorMsg);
        }
      } else if (response.statusCode == 404) {
        _logger.warning('Strategy not found (404): ID $id');
        throw Exception('Strategy with the specified ID was not found.');
      } else {
        _logger.warning(
            'API returned code ${response.statusCode}. Response: ${response.body}');
        throw Exception('API returned code ${response.statusCode}.');
      }
    } catch (e, stackTrace) {
      _logger.severe('Error getting strategy (ID: $id).', e, stackTrace);
      if (e is FormatException) {
        throw Exception('API response could not be read (invalid format).');
      }
      throw Exception('An error occurred while retrieving the strategy.');
    }
  }

  /// Create a new strategy
  static Future<BacktestStrategy> createStrategy(
      BacktestStrategy strategy) async {
    final url = Uri.parse('$baseUrl/backtesting/strategies');
    _logger.info('POST request (new strategy): $url');

    try {
      // Prepare JSON data to send and log it (no sensitive data)
      final strategyJson = strategy.toJson();
      // Remove ID if present (will be assigned by server)
      strategyJson.remove('id');
      strategyJson.remove('performance'); // Performance info not sent

      final requestBody = json.encode(strategyJson);
      _logger.fine('Request Body: $requestBody');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: requestBody,
          )
          .timeout(const Duration(seconds: 15));

      _logger.info('Response received: ${response.statusCode}');

      if (response.statusCode == 201) {
        // Successful creation code
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonResponse = json.decode(decodedBody);

        if (jsonResponse is Map &&
            jsonResponse.containsKey('status') &&
            jsonResponse['status'] == 'success') {
          if (jsonResponse.containsKey('strategy') &&
              jsonResponse['strategy'] is Map) {
            final createdStrategy = BacktestStrategy.fromJson(
                jsonResponse['strategy'] as Map<String, dynamic>);
            _logger.info(
                'Strategy successfully created: ${createdStrategy.name} (ID: ${createdStrategy.id})');
            return createdStrategy;
          } else {
            _logger.warning(
                "API response successful (201) but 'strategy' object missing/wrong format.");
            throw Exception(
                "API response format not as expected (strategy object missing).");
          }
        } else {
          final errorMsg =
              (jsonResponse is Map && jsonResponse.containsKey('message'))
                  ? jsonResponse['message']
                  : 'API returned unsuccessful response (201)';
          _logger.warning('API error (status != success): $errorMsg');
          throw Exception(errorMsg);
        }
      } else {
        _logger.warning(
            'API returned code ${response.statusCode}. Response: ${response.body}');

        // Try to parse error message
        String errorMessage =
            'Strategy could not be created (${response.statusCode}).';
        try {
          final errorJson = json.decode(utf8.decode(response.bodyBytes));
          if (errorJson is Map && errorJson.containsKey('message')) {
            errorMessage = errorJson['message'];
          }
        } catch (_) {} // Ignore parsing errors

        throw Exception(errorMessage);
      }
    } catch (e, stackTrace) {
      _logger.severe('Error creating strategy.', e, stackTrace);
      if (e is FormatException) {
        throw Exception('API response could not be read (invalid format).');
      }
      throw Exception('An error occurred while creating the strategy.');
    }
  }

  /// Update an existing strategy
  static Future<BacktestStrategy> updateStrategy(
      BacktestStrategy strategy) async {
    if (strategy.id == null || strategy.id!.isEmpty) {
      const errorMsg =
          'Strategy ID is required for updates and cannot be empty.';
      _logger.severe(errorMsg);
      throw ArgumentError(errorMsg);
    }

    final url = Uri.parse('$baseUrl/backtesting/strategies/${strategy.id}');
    _logger.info('PUT request (strategy update): $url');

    try {
      final strategyJson = strategy.toJson();
      // ID should be included in the URL path, and performance is not updated
      strategyJson.remove('performance');
      final requestBody = json.encode(strategyJson);
      _logger.fine('Request Body: $requestBody');

      final response = await http
          .put(
            url,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: requestBody,
          )
          .timeout(const Duration(seconds: 15));

      _logger.info('Response received: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonResponse = json.decode(decodedBody);

        if (jsonResponse is Map &&
            jsonResponse.containsKey('status') &&
            jsonResponse['status'] == 'success') {
          if (jsonResponse.containsKey('strategy') &&
              jsonResponse['strategy'] is Map) {
            final updatedStrategy = BacktestStrategy.fromJson(
                jsonResponse['strategy'] as Map<String, dynamic>);
            _logger.info(
                'Strategy successfully updated: ${updatedStrategy.name} (ID: ${updatedStrategy.id})');
            return updatedStrategy;
          } else {
            _logger.warning(
                "API response successful (200) but 'strategy' object missing/wrong format.");
            throw Exception(
                "API response format not as expected (strategy object missing).");
          }
        } else {
          final errorMsg =
              (jsonResponse is Map && jsonResponse.containsKey('message'))
                  ? jsonResponse['message']
                  : 'API returned unsuccessful response (200)';
          _logger.warning('API error (status != success): $errorMsg');
          throw Exception(errorMsg);
        }
      } else if (response.statusCode == 404) {
        _logger
            .warning('Strategy to update not found (404): ID ${strategy.id}');
        throw Exception('Strategy to update was not found.');
      } else {
        _logger.warning(
            'API returned code ${response.statusCode}. Response: ${response.body}');

        String errorMessage =
            'Strategy could not be updated (${response.statusCode}).';
        try {
          final errorJson = json.decode(utf8.decode(response.bodyBytes));
          if (errorJson is Map && errorJson.containsKey('message')) {
            errorMessage = errorJson['message'];
          }
        } catch (_) {} // Ignore parsing errors

        throw Exception(errorMessage);
      }
    } catch (e, stackTrace) {
      _logger.severe(
          'Error updating strategy (ID: ${strategy.id}).', e, stackTrace);
      if (e is FormatException) {
        throw Exception('API response could not be read (invalid format).');
      }
      throw Exception('An error occurred while updating the strategy.');
    }
  }

  /// Delete a strategy
  static Future<bool> deleteStrategy(String id) async {
    if (id.isEmpty) {
      const errorMsg =
          'Strategy ID is required for deletion and cannot be empty.';
      _logger.severe(errorMsg);
      throw ArgumentError(errorMsg);
    }

    final url = Uri.parse('$baseUrl/backtesting/strategies/$id');
    _logger.info('DELETE request (strategy deletion): $url');

    try {
      final response =
          await http.delete(url).timeout(const Duration(seconds: 15));

      _logger.info('Response received: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        // 204 No Content is also successful
        // Check response body if available
        bool success = true;
        String message = "Strategy successfully deleted.";

        if (response.body.isNotEmpty) {
          try {
            final decodedBody = utf8.decode(response.bodyBytes);
            final jsonResponse = json.decode(decodedBody);

            if (jsonResponse is Map && jsonResponse.containsKey('status')) {
              success = jsonResponse['status'] == 'success';
              if (jsonResponse.containsKey('message')) {
                message = jsonResponse['message'];
              }
            } else {
              // If not in JSON format or no status field, 200/204 is sufficient for success
              success = true;
            }
          } catch (e) {
            // JSON parse error but 200/204 status code is still considered successful
            _logger.warning(
                "Delete response is not in JSON format or could not be parsed, but status code ${response.statusCode} indicates success.",
                e);
            success = true;
          }
        } else {
          // Empty body with 200/204 means success
          success = true;
        }

        if (success) {
          _logger.info(message);
        } else {
          _logger
              .warning('Strategy could not be deleted (API message): $message');
        }

        return success;
      } else if (response.statusCode == 404) {
        _logger.warning('Strategy to delete not found (404): ID $id');
        throw Exception('Strategy to delete was not found.');
      } else {
        _logger.warning(
            'API returned code ${response.statusCode}. Response: ${response.body}');

        String errorMessage =
            'Strategy could not be deleted (${response.statusCode}).';
        try {
          final errorJson = json.decode(utf8.decode(response.bodyBytes));
          if (errorJson is Map && errorJson.containsKey('message')) {
            errorMessage = errorJson['message'];
          }
        } catch (_) {} // Ignore parsing errors

        throw Exception(errorMessage);
      }
    } catch (e, stackTrace) {
      _logger.severe('Error deleting strategy (ID: $id).', e, stackTrace);
      if (e is FormatException) {
        throw Exception('API response could not be read (invalid format).');
      }
      throw Exception('An error occurred while deleting the strategy.');
    }
  }

  /// Get available technical indicators
  static Future<List<Map<String, dynamic>>> getAvailableIndicators() async {
    final url = Uri.parse('$baseUrl/backtesting/indicators');
    _logger.info('GET request (indicators): $url');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      _logger.info('Response received: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonResponse = json.decode(decodedBody);

        if (jsonResponse is Map &&
            jsonResponse.containsKey('status') &&
            jsonResponse['status'] == 'success') {
          if (jsonResponse.containsKey('indicators') &&
              jsonResponse['indicators'] is List) {
            // Convert the list directly to List<Map<String, dynamic>>
            final indicators = List<Map<String, dynamic>>.from(
                (jsonResponse['indicators'] as List)
                    .map((item) => item as Map<String, dynamic>));

            _logger.info(
                '${indicators.length} indicators successfully retrieved.');
            return indicators;
          } else {
            _logger.warning(
                "API response successful but 'indicators' list missing/wrong format.");
            throw Exception(
                "API response format not as expected (indicators list missing).");
          }
        } else {
          final errorMsg =
              (jsonResponse is Map && jsonResponse.containsKey('message'))
                  ? jsonResponse['message']
                  : 'API returned unsuccessful response';
          _logger.warning('API error (status != success): $errorMsg');
          throw Exception(errorMsg);
        }
      } else {
        _logger.warning(
            'API returned code ${response.statusCode}. Response: ${response.body}');
        throw Exception('API returned code ${response.statusCode}.');
      }
    } catch (e, stackTrace) {
      _logger.severe(
          'Error getting indicators. Returning default list.', e, stackTrace);
      // Return default (placeholder) indicators
      return _getDefaultIndicators();
    }
  }

  // Default indicators list (used if API fails)
  static List<Map<String, dynamic>> _getDefaultIndicators() {
    return [
      {
        'name': 'Moving Average',
        'abbr': 'MA',
        'params': ['Period', 'Type']
      },
      {
        'name': 'Relative Strength Index',
        'abbr': 'RSI',
        'params': ['Period']
      },
      {
        'name': 'MACD',
        'abbr': 'MACD',
        'params': ['Fast', 'Slow', 'Signal']
      },
      {
        'name': 'Bollinger Bands',
        'abbr': 'BB',
        'params': ['Period', 'StdDev']
      },
      {
        'name': 'ATR',
        'abbr': 'ATR',
        'params': ['Period']
      },
      {
        'name': 'Stochastic',
        'abbr': 'STOCH',
        'params': ['K', 'D', 'Smooth']
      },
    ];
  }

  /// Run a backtest with improved handling for Infinity values in JSON
  static Future<BacktestResult> runBacktest({
    required String ticker,
    required String timeframe,
    required String periodStr,
    required BacktestStrategy strategy,
    double initialCapital = 10000.0,
  }) async {
    final url = Uri.parse('$baseUrl/backtesting/run');
    _logger.info('POST request (run backtest): $url');

    try {
      // Get the strategy JSON without ID and performance
      final strategyJson = strategy.toJson();
      strategyJson.remove('id');
      strategyJson.remove('performance');

      // Prepare the request body
      final Map<String, dynamic> requestBody = {
        'ticker': ticker.trim().toUpperCase(),
        'timeframe': timeframe,
        'period': periodStr.trim(),
        'initial_capital': initialCapital,
        'strategy': strategyJson,
      };

      // Log the request body (avoid sensitive data)
      final requestBodyString = json.encode(requestBody);
      if (requestBodyString.length < 1000) {
        _logger.fine('Request Body: $requestBodyString');
      } else {
        _logger.fine(
            'Request Body (first 1000 chars): ${requestBodyString.substring(0, 1000)}...');
      }

      // Send the request
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: requestBodyString,
          )
          .timeout(const Duration(seconds: 120));

      _logger.info('Response received: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);

        // Pre-process the response to handle Infinity, -Infinity, and NaN values
        // which are valid in JavaScript but not in standard JSON
        final String processedBody = decodedBody
            .replaceAll(': Infinity,', ': "Infinity",')
            .replaceAll(':-Infinity,', ':"-Infinity",')
            .replaceAll(':NaN,', ':"NaN",')
            .replaceAll(': Infinity}', ': "Infinity"}')
            .replaceAll(':-Infinity}', ':"-Infinity"}')
            .replaceAll(':NaN}', ':"NaN"}');

        // Log processed body for debugging (if not too large)
        if (processedBody.length < 1000) {
          _logger.fine('Processed response body: $processedBody');
        }

        Map<String, dynamic> jsonResponse;
        try {
          jsonResponse = json.decode(processedBody);
          _logger.fine('Raw API response structure: ${jsonResponse.keys}');
        } catch (e) {
          _logger.severe("JSON parsing error after processing: $e");
          _logger.fine(
              "First 500 chars of processed body: ${processedBody.substring(0, min(500, processedBody.length))}");
          // Re-throw with more context
          throw FormatException(
              "Could not parse API response even after handling special values: $e");
        }

        if (jsonResponse is Map &&
            jsonResponse.containsKey('status') &&
            jsonResponse['status'] == 'success') {
          // Extract the results node which contains our data
          Map<String, dynamic> resultData;
          if (jsonResponse.containsKey('results')) {
            resultData = Map<String, dynamic>.from(jsonResponse['results']);
            _logger.info('Successfully extracted results data');
          } else {
            _logger.warning(
                'No results field found in API response, using entire response');
            resultData = Map<String, dynamic>.from(jsonResponse);
          }

          try {
            final result = BacktestResult.fromJson(resultData);
            _logger.info(
                'Backtest completed successfully. Trades: ${result.tradeHistory.length}, Equity points: ${result.equityCurve.length}');

            // Log a small sample of data to verify parsing
            if (result.tradeHistory.isNotEmpty) {
              _logger.fine('First trade: ${result.tradeHistory.first}');
            }
            if (result.equityCurve.isNotEmpty) {
              _logger.fine(
                  'First and last equity points: ${result.equityCurve.first} -> ${result.equityCurve.last}');
            }

            return result;
          } catch (e, stackTrace) {
            _logger.severe(
                "Error parsing backtest result JSON: $e", e, stackTrace);
            throw Exception("Backtest result could not be parsed: $e");
          }
        } else {
          final errorMsg =
              (jsonResponse is Map && jsonResponse.containsKey('message'))
                  ? jsonResponse['message']
                  : 'API returned unsuccessful response';
          _logger.warning('API error (status != success): $errorMsg');
          throw Exception(errorMsg);
        }
      } else {
        _logger.warning(
            'API returned code ${response.statusCode}. Response: ${response.body}');

        String errorMessage =
            'Backtest could not be run (${response.statusCode}).';
        try {
          final errorJson = json.decode(utf8.decode(response.bodyBytes));
          if (errorJson is Map && errorJson.containsKey('message')) {
            errorMessage = errorJson['message'];
          }
        } catch (_) {} // Ignore parsing errors

        throw Exception(errorMessage);
      }
    } catch (e, stackTrace) {
      _logger.severe('Error running backtest: $e', e, stackTrace);
      throw Exception('An error occurred while running the backtest: $e');
    }
  }

  // Helper function for min value (used in logging)
  static int min(int a, int b) {
    return a < b ? a : b;
  }
}
