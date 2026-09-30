import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Van Route Management',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFFFAF7),
      ),
      home: const VanRoutePage(),
    );
  }
}

class VanRoutePage extends StatefulWidget {
  const VanRoutePage({super.key});

  @override
  State<VanRoutePage> createState() => _VanRoutePageState();
}

class _VanRoutePageState extends State<VanRoutePage> {
  final ApiService apiService = ApiService();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> vanNumbers = [];
  List<Map<String, dynamic>> routeCodes = [];
  List<Map<String, dynamic>> vanRoutes = [];

  String? selectedVanNumber;
  String? selectedRouteCode;

  bool isActive = true;
  DateTime? assignedDate;

  int? editingId;
  bool isLoading = false;

  // ---------------------------------------------------------
  // INIT
  // ---------------------------------------------------------

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  // ---------------------------------------------------------
  // LOAD DATA
  // ---------------------------------------------------------

  Future<void> loadInitialData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final vans = await apiService.getVanNumbers();
      final routes = await apiService.getRouteCodes();
      final records = await apiService.getAllVanRoutes();

      if (!mounted) return;

      setState(() {
        vanNumbers = vans;
        routeCodes = routes;
        vanRoutes = records;
      });
    } catch (e) {
      showMessage(
        'Failed to load data: $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> loadRoutes() async {
    try {
      final records = await apiService.getAllVanRoutes();

      if (!mounted) return;

      setState(() {
        vanRoutes = records;
      });
    } catch (e) {
      showMessage(
        'Failed to refresh: $e',
        isError: true,
      );
    }
  }

  // ---------------------------------------------------------
  // DATE PICKER
  // ---------------------------------------------------------

  Future<void> selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: assignedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        assignedDate = picked;
      });
    }
  }

  // ---------------------------------------------------------
  // CREATE / UPDATE
  // ---------------------------------------------------------

  Future<void> saveVanRoute() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (assignedDate == null) {
      showMessage(
        'Please select Assigned Date',
        isError: true,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final String dateString =
          '${assignedDate!.year}-'
          '${assignedDate!.month.toString().padLeft(2, '0')}-'
          '${assignedDate!.day.toString().padLeft(2, '0')}';

      // CREATE
      if (editingId == null) {
        await apiService.createVanRoute(
          vanNumber: selectedVanNumber!,
          routeCode: selectedRouteCode!,
          isActive: isActive,
          assignedDate: dateString,
        );

        showMessage(
          'Van Route created successfully',
        );
      }

      // UPDATE
      else {
        await apiService.updateVanRoute(
          id: editingId!,
          vanNumber: selectedVanNumber!,
          routeCode: selectedRouteCode!,
          isActive: isActive,
          assignedDate: dateString,
        );

        showMessage(
          'Van Route updated successfully',
        );
      }

      resetForm();
      await loadRoutes();
    } catch (e) {
      showMessage(
        e.toString(),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ---------------------------------------------------------
  // EDIT
  // ---------------------------------------------------------

  Future<void> editVanRoute(
      Map<String, dynamic> item,
      ) async {
    try {
      setState(() {
        isLoading = true;
      });

      final int id = int.parse(
        item['vanRouteId'].toString(),
      );

      final data = await apiService.getVanRoute(id);

      if (!mounted) return;

      setState(() {
        editingId = id;

        // -------------------------------------------------
        // IMPORTANT:
        // Van dropdown uses API "value" as selected value.
        // GetOne returns the van "name".
        // So find the matching value using the name.
        // -------------------------------------------------

        final van = vanNumbers.firstWhere(
              (item) =>
          item['name']?.toString() ==
              data['vanNumber']?.toString(),
          orElse: () => {},
        );

        selectedVanNumber =
            van['value']?.toString();

        // Route code is already the API value.
        selectedRouteCode =
            data['routeCode']?.toString();

        isActive =
            data['isActive'] == true;

        if (data['assignedDate'] != null) {
          assignedDate = DateTime.tryParse(
            data['assignedDate'].toString(),
          );
        }
      });

      showMessage(
        'Record loaded for editing',
      );
    } catch (e) {
      showMessage(
        'Failed to load record: $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ---------------------------------------------------------
  // VIEW
  // ---------------------------------------------------------

  Future<void> viewVanRoute(
      Map<String, dynamic> item,
      ) async {
    try {
      setState(() {
        isLoading = true;
      });

      final int id = int.parse(
        item['vanRouteId'].toString(),
      );

      final data = await apiService.getVanRoute(id);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: const Color(0xFFF9F4FF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE5FF),
                    borderRadius:
                    BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.alt_route,
                    color: Color(0xFF8D75D8),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Route Details',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                detailRow(
                  Icons.local_shipping_outlined,
                  'Van Number',
                  data['vanNumber']?.toString() ?? '-',
                ),
                const SizedBox(height: 14),
                detailRow(
                  Icons.alt_route,
                  'Route Code',
                  data['routeCode']?.toString() ?? '-',
                ),
                const SizedBox(height: 14),
                detailRow(
                  Icons.calendar_month_outlined,
                  'Assigned Date',
                  data['assignedDate']?.toString() ?? '-',
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(
                      'Status',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    statusBadge(
                      data['isActive'] == true,
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'Close',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF8067CC),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      showMessage(
        'Failed to load details: $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ---------------------------------------------------------
  // DELETE
  // ---------------------------------------------------------

  Future<void> deleteVanRoute(int id) async {
    final bool? confirm =
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete Van Route?',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this record?',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.grey[700],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                const Color(0xFFE58B91),
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      await apiService.deleteVanRoute(id);

      showMessage(
        'Deleted successfully',
      );

      await loadRoutes();
    } catch (e) {
      showMessage(
        'Delete failed: $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ---------------------------------------------------------
  // RESET
  // ---------------------------------------------------------

  void resetForm() {
    setState(() {
      selectedVanNumber = null;
      selectedRouteCode = null;
      isActive = true;
      assignedDate = null;
      editingId = null;
    });

    formKey.currentState?.reset();
  }

  // ---------------------------------------------------------
  // MESSAGE
  // ---------------------------------------------------------

  void showMessage(
      String message, {
        bool isError = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: isError
              ? const Color(0xFFE58B91)
              : const Color(0xFF7DB89D),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.all(12),
        ),
      );
  }

  // ---------------------------------------------------------
  // DETAIL ROW
  // ---------------------------------------------------------

  Widget detailRow(
      IconData icon,
      String title,
      String value,
      ) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF8D75D8),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------
  // STATUS BADGE
  // ---------------------------------------------------------

  Widget statusBadge(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFFDFF2E7)
            : const Color(0xFFF9DFE1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? const Color(0xFF55A879)
                  : const Color(0xFFD66F78),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            active ? 'ACTIVE' : 'INACTIVE',
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: active
                  ? const Color(0xFF4B9169)
                  : const Color(0xFFC65D67),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF7),
      body: Stack(
        children: [
          RefreshIndicator(
            color: const Color(0xFF8D75D8),
            onRefresh: loadRoutes,
            child: CustomScrollView(
              physics:
              const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ------------------------------------------------
                // HEADER
                // ------------------------------------------------
                SliverAppBar(
                  expandedHeight: 145,
                  pinned: true,
                  automaticallyImplyLeading: false,
                  backgroundColor:
                  const Color(0xFF9B85E8),
                  elevation: 0,
                  flexibleSpace:
                  FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF9B85E8),
                            Color(0xFFDDB3DC),
                          ],
                          begin:
                          Alignment.topLeft,
                          end:
                          Alignment.bottomRight,
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding:
                          const EdgeInsets.fromLTRB(
                            18,
                            15,
                            18,
                            12,
                          ),
                          child: Row(
                            crossAxisAlignment:
                            CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration:
                                BoxDecoration(
                                  color: Colors.white
                                      .withOpacity(0.9),
                                  borderRadius:
                                  BorderRadius
                                      .circular(14),
                                ),
                                child: const Icon(
                                  Icons.local_shipping,
                                  color:
                                  Color(0xFF8D75D8),
                                  size: 27,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment:
                                  MainAxisAlignment
                                      .center,
                                  crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                                  children: [
                                    Text(
                                      'Van Route',
                                      style:
                                      GoogleFonts
                                          .poppins(
                                        color:
                                        Colors.white,
                                        fontSize: 18,
                                        fontWeight:
                                        FontWeight.w700,
                                        height: 1.0,
                                      ),
                                    ),
                                    Text(
                                      'Management',
                                      style:
                                      GoogleFonts
                                          .poppins(
                                        color:
                                        Colors.white,
                                        fontSize: 18,
                                        fontWeight:
                                        FontWeight.w700,
                                        height: 1.0,
                                      ),
                                    ),
                                    const SizedBox(
                                        height: 3),
                                    Text(
                                      'Manage your routes easily',
                                      style:
                                      GoogleFonts
                                          .poppins(
                                        color: Colors.white
                                            .withOpacity(
                                            0.85),
                                        fontSize: 9,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed:
                                loadRoutes,
                                style:
                                IconButton.styleFrom(
                                  backgroundColor:
                                  Colors.white
                                      .withOpacity(
                                      0.25),
                                ),
                                icon: const Icon(
                                  Icons.refresh,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ------------------------------------------------
                // CONTENT
                // ------------------------------------------------
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    12,
                    14,
                    12,
                    30,
                  ),
                  sliver: SliverList(
                    delegate:
                    SliverChildListDelegate([
                      buildForm(),
                      const SizedBox(height: 20),
                      buildRouteList(),
                    ]),
                  ),
                ),
              ],
            ),
          ),

          // -----------------------------------------------------
          // LOADING
          // -----------------------------------------------------

          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.12),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF8D75D8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // FORM
  // ---------------------------------------------------------

  Widget buildForm() {
    final bool editing = editingId != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE6D9EC),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                  const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                    const Color(0xFFF0E9FF),
                    borderRadius:
                    BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.tune,
                    size: 19,
                    color: Color(0xFF8067CC),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      editing
                          ? 'Edit Van Route'
                          : 'Add Van Route',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),
                    Text(
                      editing
                          ? 'Update assignment'
                          : 'Create a new assignment',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // VAN NUMBER
            DropdownButtonFormField<String>(
              value: selectedVanNumber,
              isExpanded: true,
              decoration:
              inputDecoration(
                'Van Number',
                Icons.local_shipping_outlined,
              ),
              items: vanNumbers.map((van) {
                final String? value =
                van['value']?.toString();

                final String display =
                    van['name']?.toString() ??
                        value ??
                        '';

                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    display,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedVanNumber = value;
                });
              },
              validator: (value) {
                if (value == null ||
                    value.isEmpty) {
                  return 'Please select Van Number';
                }
                return null;
              },
            ),

            const SizedBox(height: 8),

            // ROUTE CODE
            DropdownButtonFormField<String>(
              value: selectedRouteCode,
              isExpanded: true,
              decoration:
              inputDecoration(
                'Route Code',
                Icons.alt_route,
              ),
              items: routeCodes.map((route) {
                final String? value =
                route['value']?.toString();

                final String display =
                    route['name']?.toString() ??
                        value ??
                        '';

                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    display,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedRouteCode = value;
                });
              },
              validator: (value) {
                if (value == null ||
                    value.isEmpty) {
                  return 'Please select Route Code';
                }
                return null;
              },
            ),

            const SizedBox(height: 8),

            // DATE
            InkWell(
              onTap: selectDate,
              borderRadius:
              BorderRadius.circular(10),
              child: InputDecorator(
                decoration:
                inputDecoration(
                  'Assigned Date',
                  Icons.calendar_month_outlined,
                ),
                child: Text(
                  assignedDate == null
                      ? 'Select assigned date'
                      : '${assignedDate!.day.toString().padLeft(2, '0')}-'
                      '${assignedDate!.month.toString().padLeft(2, '0')}-'
                      '${assignedDate!.year}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: assignedDate == null
                        ? Colors.grey[500]
                        : const Color(0xFF302B35),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ACTIVE
            Container(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8F3),
                borderRadius:
                BorderRadius.circular(11),
                border: Border.all(
                  color:
                  const Color(0xFFF0DCD0),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active Route',
                          style:
                          GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),
                        Text(
                          isActive
                              ? 'Currently active'
                              : 'Currently inactive',
                          style:
                          GoogleFonts.poppins(
                            fontSize: 8,
                            color:
                            Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isActive,
                    activeThumbColor:
                    const Color(0xFF70B69A),
                    activeTrackColor:
                    const Color(0xFFCBE5D8),
                    onChanged: (value) {
                      setState(() {
                        isActive = value;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // BUTTONS
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: saveVanRoute,
                      icon: Icon(
                        editing
                            ? Icons.save_outlined
                            : Icons.add,
                        size: 16,
                      ),
                      label: Text(
                        editing
                            ? 'Update Route'
                            : 'Create Route',
                        style:
                        GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                      style:
                      ElevatedButton.styleFrom(
                        backgroundColor:
                        const Color(0xFF8D75D8),
                        foregroundColor:
                        Colors.white,
                        elevation: 0,
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(
                              10),
                        ),
                      ),
                    ),
                  ),
                ),

                if (editing) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 40,
                    child: OutlinedButton(
                      onPressed: resetForm,
                      style:
                      OutlinedButton.styleFrom(
                        foregroundColor:
                        const Color(0xFF6D6373),
                        side: const BorderSide(
                          color: Color(0xFFD8CCD9),
                        ),
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(
                              10),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style:
                        GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // INPUT DECORATION
  // ---------------------------------------------------------

  InputDecoration inputDecoration(
      String label,
      IconData icon,
      ) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(
        fontSize: 10,
        color: Colors.grey[600],
      ),
      prefixIcon: Icon(
        icon,
        size: 17,
        color: const Color(0xFF8C7AA5),
      ),
      filled: true,
      fillColor: const Color(0xFFFFF9F5),
      contentPadding:
      const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFFF0DCD0),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFFF0DCD0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFFB59CEB),
          width: 1.5,
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // ROUTE LIST
  // ---------------------------------------------------------

  Widget buildRouteList() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    'Van Routes',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Existing route assignments',
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color:
                const Color(0xFFF0E9FF),
                borderRadius:
                BorderRadius.circular(20),
              ),
              child: Text(
                '${vanRoutes.length} Routes',
                style: GoogleFonts.poppins(
                  fontSize: 8,
                  fontWeight:
                  FontWeight.w600,
                  color:
                  const Color(0xFF8067CC),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        if (vanRoutes.isEmpty)
          Container(
            width: double.infinity,
            padding:
            const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.route_outlined,
                  size: 35,
                  color: Color(0xFFB7A8C4),
                ),
                const SizedBox(height: 8),
                Text(
                  'No Van Routes found',
                  style:
                  GoogleFonts.poppins(
                    fontSize: 12,
                    color:
                    Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

        ...vanRoutes.map(
              (item) => buildRouteCard(item),
        ),
      ],
    );
  }

  // ---------------------------------------------------------
  // ROUTE CARD
  // ---------------------------------------------------------

  Widget buildRouteCard(
      Map<String, dynamic> item,
      ) {
    final int id = int.parse(
      item['vanRouteId'].toString(),
    );

    final bool active =
        item['isActive'] == true;

    return Container(
      margin:
      const EdgeInsets.only(bottom: 10),
      padding:
      const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFE6D9EC),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color:
                  const Color(0xFFF0E9FF),
                  borderRadius:
                  BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  color: Color(0xFF8067CC),
                  size: 21,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['vanNumber']
                          ?.toString() ??
                          '-',
                      style:
                      GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.alt_route,
                          size: 12,
                          color:
                          Color(0xFF8C7AA5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item['routeCode']
                              ?.toString() ??
                              '-',
                          style:
                          GoogleFonts.poppins(
                            fontSize: 9,
                            color:
                            Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              statusBadge(active),
            ],
          ),

          const SizedBox(height: 9),

          Container(
            width: double.infinity,
            padding:
            const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color:
              const Color(0xFFFFF8F3),
              borderRadius:
              BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  size: 15,
                  color: Color(0xFF8C7AA5),
                ),
                const SizedBox(width: 7),
                Text(
                  'Assigned',
                  style: GoogleFonts.poppins(
                    fontSize: 8,
                    color: Colors.grey[500],
                  ),
                ),
                const Spacer(),
                Text(
                  item['assignedDate']
                      ?.toString() ??
                      '-',
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 9),

          Row(
            children: [
              Expanded(
                child: actionButton(
                  icon: Icons.visibility_outlined,
                  label: 'View',
                  onPressed: () {
                    viewVanRoute(item);
                  },
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: actionButton(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  onPressed: () {
                    editVanRoute(item);
                  },
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: actionButton(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  delete: true,
                  onPressed: () {
                    deleteVanRoute(id);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // ACTION BUTTON
  // ---------------------------------------------------------

  Widget actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool delete = false,
  }) {
    return SizedBox(
      height: 34,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 15,
        ),
        label: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: delete
              ? const Color(0xFFD66F78)
              : const Color(0xFF76658A),
          side: BorderSide(
            color: delete
                ? const Color(0xFFF0BFC4)
                : const Color(0xFFE1D6E5),
          ),
          padding:
          const EdgeInsets.symmetric(
            horizontal: 4,
          ),
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(9),
          ),
        ),
      ),
    );
  }
}