FC ?= gfortran
FFLAGS ?= -O3 -fPIC
PREFIX ?= /usr/local

SRC_DIR = src
APP_DIR = app
BUILD_DIR = build
BIN_DIR = $(BUILD_DIR)/bin
OBJ_DIR = $(BUILD_DIR)/obj

MODULE_SRCS = \
	$(SRC_DIR)/data_parameters.f90 \
	$(SRC_DIR)/flake_derivedtypes.f90 \
	$(SRC_DIR)/flake_parameters.f90 \
	$(SRC_DIR)/flake_configure.f90 \
	$(SRC_DIR)/flake_albedo_ref.f90 \
	$(SRC_DIR)/flake_paramoptic_ref.f90 \
	$(SRC_DIR)/flake.f90 \
	$(SRC_DIR)/SfcFlx.f90 \
	$(SRC_DIR)/src_flake_interface_1D.f90

MODULE_OBJS = $(patsubst $(SRC_DIR)/%.f90,$(OBJ_DIR)/%.o,$(MODULE_SRCS))

TARGET = $(BIN_DIR)/flake
LIBTARGET = $(BUILD_DIR)/libflake.a

.PHONY: all clean test install

all: $(TARGET) $(LIBTARGET)

$(TARGET): $(LIBTARGET) $(APP_DIR)/flake_cli.f90 | $(BIN_DIR)
	$(FC) $(FFLAGS) -I$(OBJ_DIR) $(APP_DIR)/flake_cli.f90 $(LIBTARGET) -o $@

$(LIBTARGET): $(MODULE_OBJS)
	ar rcs $@ $^

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.f90 | $(OBJ_DIR)
	$(FC) $(FFLAGS) -J$(OBJ_DIR) -I$(SRC_DIR) -c $< -o $@

$(OBJ_DIR):
	mkdir -p $(OBJ_DIR)

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

test: $(TARGET)
	@echo "=== Running FLake Verification Tests ==="
	$(TARGET) examples/Heiligensee80-96/Heiligensee80-96.nml
	$(TARGET) examples/Mueggelsee80-96/Mueggelsee80-96.nml
	$(TARGET) examples/Stechlin94-98/Stechlin94-98.nml
	@echo "All tests passed successfully!"

clean:
	rm -rf $(BUILD_DIR)
	rm -f examples/*/*.rslt

install: $(TARGET) $(LIBTARGET)
	install -d $(DESTDIR)$(PREFIX)/bin $(DESTDIR)$(PREFIX)/lib $(DESTDIR)$(PREFIX)/include/flake
	install -m 755 $(TARGET) $(DESTDIR)$(PREFIX)/bin/
	install -m 644 $(LIBTARGET) $(DESTDIR)$(PREFIX)/lib/
	install -m 644 $(SRC_DIR)/*.f90 $(SRC_DIR)/*.incf $(DESTDIR)$(PREFIX)/include/flake/
