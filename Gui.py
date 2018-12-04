from PyQt4.QtCore import *
from PyQt4.QtGui import *
import sys, os

class Gui(QMainWindow):
	def __init__(self):
		super().__init__()
		self.setWindowTitle('Ensambla IDE v. 0.0.1');
		self.main_widget = QWidget()
		self.main_layout = QHBoxLayout()
		self.main_splitter = QSplitter(Qt.Horizontal)

		self.workspace = QWidget()
		self.workspace_layout = QVBoxLayout()

		self.options = QWidget()
		self.options_layout = QVBoxLayout()

		self.editor = Editor()
		self.editor.editor.setTabStopWidth(20)
		
		self.terminal = IntegratedTerminal()
		self.editor.setTerminal(self.terminal)
		self.workspace_splitter = QSplitter(Qt.Vertical)

		self.arch_list = ArchitectureModule(self.terminal)

		self.tools = ToolBar(self.arch_list)
		self.tools.setEditor(self.editor)

		self.workspace_splitter.addWidget(self.editor)
		self.workspace_splitter.addWidget(self.terminal)
		self.workspace_splitter.setSizes([300,200])
		self.workspace_layout.addWidget(self.workspace_splitter)
		self.workspace.setLayout(self.workspace_layout)

		self.options_layout.addWidget(self.tools)
		self.options_layout.addWidget(self.arch_list)
		self.options.setLayout(self.options_layout)

		self.main_splitter.addWidget(self.workspace)
		self.main_splitter.addWidget(self.options)
		self.main_splitter.setSizes([250,150])
		self.main_layout.addWidget(self.main_splitter)

		self.main_widget.setLayout(self.main_layout)
		self.setCentralWidget(self.main_widget)

class Editor(QWidget):
	def __init__(self, terminal=None):
		super().__init__()
		self.editor = QPlainTextEdit()
		self.editor.setMinimumWidth(400)
		self.editor_layout = QHBoxLayout()
		self.editor_layout.addWidget(self.editor)
		self.setLayout(self.editor_layout)

		f = QFont();
		f.setPointSize(12);
		self.editor.setFont(f);

		self.terminal = terminal

	def setTerminal(self, terminal):
		self.terminal = terminal

	def setTools(self, toolbar):
		self.toolbar = toolbar

class IntegratedTerminal(QWidget):
	def __init__(self):
		super().__init__()
		self.terminal_layout = QVBoxLayout()
		self.terminal = QPlainTextEdit()
		self.terminal.setReadOnly(True)
		self.terminal.setStyleSheet("""
			background-color:rgb(0,0,0);
			color:rgb(255,255,255)
		""")
		f = QFont();
		f.setPointSize(12);
		self.terminal.setFont(f);

		self.terminal_layout.addWidget(self.terminal)
		self.setLayout(self.terminal_layout)

class ToolBar(QWidget):
	def __init__(self, arch_module):
		super().__init__()
		self.toolbar_widget = QWidget()
		self.toolbar_layout = QHBoxLayout()
		self.arch_module = arch_module

		self.new_btn = QPushButton()
		self.new_btn.setMaximumSize(30, 30)
		self.new_btn.setIcon(QIcon("assets/clear_icon.png"))
		self.new_btn.clicked.connect(self.clear)
		
		self.run_btn = QPushButton()
		self.run_btn.setMaximumSize(30, 30)
		self.run_btn.setIcon(QIcon("assets/run_icon.png"))
		self.run_btn.clicked.connect(self.run)
		
		self.toolbar_layout.addWidget(self.new_btn)
		self.toolbar_layout.addWidget(self.run_btn)
		self.setLayout(self.toolbar_layout)

		self.compile_shortcut = QShortcut(QKeySequence("Ctrl+Return"), self)
		self.compile_shortcut.activated.connect(self.run)

		self.compile_shortcut = QShortcut(QKeySequence("Ctrl+N"), self)
		self.compile_shortcut.activated.connect(self.clear)

	def setEditor(self, editor):
		self.editor = editor

	def clear(self):
		self.editor.editor.clear()

	def run(self):# ---------------------
		code = self.editor.editor.toPlainText()
		input = open("input.temp", "w")
		input.write(code)
		input.close()
		compiler = self.arch_module.selectedItems()
		if len(compiler) == 0:
			self.editor.terminal.terminal.clear()
			self.editor.terminal.terminal.appendPlainText("ERROR: Seleccione una arquitectura antes de ejecutar el programa")
			return
			
		compiler = compiler[0].text().split(".")[0]
		yacc_path = "./compilers/"+compiler+"/"+compiler+"_bison.y"
		command1 = "bison -v " + yacc_path + " -o ./compilers/" + compiler + "/" + compiler + "_bison.tab.c"
		command2 = "gcc ./compilers/" + compiler + "/" + compiler + "_bison.tab.c -w -lm -o ./compilers/" + compiler + "/compiler"
		os.system(command1 + " && " + command2)
		os.system('./compilers/' + compiler + '/compiler < input.temp > output.temp')
		output = open("output.temp","r")
		out = output.read()
		self.editor.terminal.terminal.clear()
		self.editor.terminal.terminal.appendPlainText(out)

class ArchitectureModule(QListWidget):
	def __init__(self, intgr_terminal):
		super().__init__()
		self.terminal = intgr_terminal.terminal
		arch_path = "./architectures/"
		for root, dirs, t_files in os.walk(arch_path, topdown=False):
			files = t_files

		for arch in files:
			data = open(arch_path + arch, 'r').read().split("\n")
			registers = data[0].split(":")[1]
			carry = data[1].split(":")[1]

			self.new_arch_item = QListWidgetItem(arch)
			self.new_arch_item.setData(33, registers)
			self.new_arch_item.setData(34, carry)
			self.addItem(self.new_arch_item)

		self.itemClicked.connect(self.loadArchitecture)

	def loadArchitecture(self, item):
		num_registers = item.data(33)
		carry = item.data(34)

		terminal_text = "## Arquitectura seleccionada ## "
		terminal_text += "\n> Cant. registros: {}".format(item.data(33) if item.data(33) != "-1" else "Indef")
		terminal_text += "\n> CarryBit?: {}".format("True" if item.data(34) == "1" else "False")

		self.terminal.clear()
		self.terminal.appendPlainText(terminal_text)
		self.setCurrentArch(item.data(33), item.data(34))

	def setCurrentArch(self, n_registers, carry):
		self.fixed_registers = n_registers
		self.fixed_carrybit = carry

def main():
	QApplication.setStyle("cleanlooks")
	App = QApplication(sys.argv) # Nueva aplicacion
	App_window = Gui()
	App_window.show()
	App.exec_()


if __name__ == "__main__":
	main()
