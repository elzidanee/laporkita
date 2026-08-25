import '../datasources/remote/policy_simulator_datasource.dart';
import '../models/policy_simulation_model.dart';

class PolicySimulatorRepository {
  final PolicySimulatorDatasource _datasource;

  PolicySimulatorRepository({PolicySimulatorDatasource? datasource})
      : _datasource = datasource ?? PolicySimulatorDatasource();

  Future<PolicySimulationModel> createSimulation({
    required String promptText,
    String? zoneId,
  }) {
    return _datasource.createSimulation(
      promptText: promptText,
      zoneId: zoneId,
    );
  }

  Future<List<PolicySimulationModel>> getSimulations({
    int limit = 20,
    String? cursor,
  }) async {
    final response = await _datasource.getSimulations(
      limit: limit,
      cursor: cursor,
    );
    return response.data ?? [];
  }

  Future<PolicySimulationModel> getSimulationById(String id) {
    return _datasource.getSimulationById(id);
  }
}
